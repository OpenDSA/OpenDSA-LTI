class LtiController < ApplicationController
  layout 'lti', only: [:launch]

  after_action :allow_iframe, only: [:launch, :resource, :launch_extrtool]
  # the consumer keys/secrets

  def launch
    unless params.key?(:custom_inst_book_id)
      launch_ex
      return
    end
    # must include the oauth proxy object
    require 'oauth/request_proxy/rack_request'
    @inst_book = InstBook.find_by(id: params[:custom_inst_book_id])
    @course_offering = CourseOffering.find_by(id: @inst_book.course_offering_id)
    $oauth_creds = LmsAccess.get_oauth_creds(params[:oauth_consumer_key])

    render('error') and return unless lti_authorize!
    lms_instance = ensure_lms_instance()
    render('error') and return unless ensure_user(lms_instance.id)

    lti_enroll(@course_offering)

    # I change this to be custom intanbook id becuase it is not working on mine yet
    if params.has_key?(:custom_course_offering_id)
      launch_instructor_tool()
      return
    end

    file_name = nil
    if params.key?(:custom_module_file_name)
      lms_access_id = LmsAccess.where(consumer_key: params[:oauth_consumer_key]).pluck(:id).first
      ensure_module_progress(lms_access_id)
      file_name = params[:custom_module_file_name]
    else
      file_name = params[:custom_section_file_name]
    end
    @section_html = File.read(File.join('public/OpenDSA/Books',
                                        params[:custom_book_path],
                                        '/lti_html/',
                                        "#{file_name.to_s}.html")) and return
  end

  def assessment
    request_params = JSON.parse(request.body.read.to_s)
    isFullModule = request_params.key?('instChapterModuleId')

    if isFullModule
      # we check if the module score needs to be sent to the LMS whenever
      # an exercise attempt is recorded. See odsa_module_progress.rb
      render :json => {:message => 'deprecated endpoint'}.to_json
      return
    end

    hasBook = request_params.key?('instBookId')

    if hasBook
      inst_section = InstSection.find_by(id: request_params['instSectionId'])

      @odsa_exercise_attempts = OdsaExerciseAttempt.where("inst_book_section_exercise_id=? AND user_id=?",
                                                          request_params['instBookSectionExerciseId'], current_user.id).select(
        "id, user_id, question_name, request_type,
                                  correct, worth_credit, time_done, time_taken, earned_proficiency, points_earned,
                                  pe_score, pe_steps_fixed"
      )
      @odsa_exercise_progress = OdsaExerciseProgress.where("inst_book_section_exercise_id=? AND user_id=?",
                                                           request_params['instBookSectionExerciseId'], current_user.id).select("user_id, current_score, highest_score,
                                  total_correct, proficient_date,first_done, last_done")
    else
      @odsa_exercise_attempts = OdsaExerciseAttempt.where("inst_course_offering_exercise_id=? AND user_id=?",
                                                          request_params['instCourseOfferingExerciseId'], current_user.id).select(
        "id, user_id, question_name, request_type,
                                  correct, worth_credit, time_done, time_taken, earned_proficiency, points_earned,
                                  pe_score, pe_steps_fixed"
      )
      @odsa_exercise_progress = OdsaExerciseProgress.where("inst_course_offering_exercise_id=? AND user_id=?",
                                                           request_params['instCourseOfferingExerciseId'], current_user.id).select("user_id, current_score, highest_score,
                                  total_correct, proficient_date,first_done, last_done")
    end

    a = @odsa_exercise_attempts
    b = @odsa_exercise_progress
    TableHelper.arg(a, b)
    f = render_to_string "lti/table.html.erb"

    launch_params = request_params['toParams']['launch_params']
    if launch_params
      key = launch_params['oauth_consumer_key']
      $oauth_creds = LmsAccess.get_oauth_creds(key)
    else
      @message = "The tool never launched"
      render(:error)
    end

    lti_param = {
      "lis_outcome_service_url" => "#{launch_params['lis_outcome_service_url']}",
      "lis_result_sourcedid" => "#{CGI.unescapeHTML(launch_params['lis_result_sourcedid'] || '')}",
    }

    # @tp = IMS::LTI::ToolProvider.new(key, $oauth_creds[key], launch_params)
    @tp = IMS::LTI::ToolProvider.new(key, $oauth_creds[key], lti_param)
    # add extension
    @tp.extend IMS::LTI::Extensions::OutcomeData::ToolProvider

    if !@tp.outcome_service?
      @message = "This tool wasn't lunched as an outcome service"
      render(:error)
    end

    # post the given score to the TC
    score = (request_params['toParams']['score'] != '' ? request_params['toParams']['score'] : nil)
    #res = @tp.post_replace_exercise_progressresult!(score)
    res = @tp.post_extended_replace_result!(score: score, text: f)

    if res.success?
      if hasBook
        inst_section.lms_posted = true
        inst_section.time_posted = Time.now
        inst_section.save!
      end
      render :json => {:message => 'success', :res => res.as_json}.to_json
    else
      if hasBook
        inst_section.lms_posted = false
        inst_section.save!
      end
      render :json => {:message => 'failure', :res => res.as_json}.to_json, :status => :bad_request
      error = Error.new(:class_name => 'post_replace_result_fail',
                        :message => res.inspect, :params => request_params.to_s)
      error.save!
    end
  end

  def xml_config
    host = request.scheme + "://" + request.host_with_port
    tc = IMS::LTI::ToolConfig.new(:title => "OpenDSA Tool Provider", :launch_url => host + '/lti/launch')
    tc.extend IMS::LTI::Extensions::Canvas::ToolConfig
    tc.description = "OpenDSA LTI Tool Provider supports LIS Outcome pass-back."
    tc.canvas_privacy_public!
    tc.canvas_resource_selection!({
      :url => host + '/lti/resource',
      :selection_width => 800,
      :selection_height => 600,
    })

    tc.set_canvas_ext_param(:custom_fields, {
      canvas_api_base_url: '$Canvas.api.baseUrl',
    })

    render xml: tc.to_xml(:indent => 2), :content_type => 'text/xml'
  end

  def resource
    # must include the oauth proxy object
    require 'oauth/request_proxy/rack_request'
    $oauth_creds = LmsAccess.get_oauth_creds(params[:oauth_consumer_key])
    if $oauth_creds.blank?
      @message = 'Please make sure the consumer key is set correctly in the tool configuration in the LMS.'
      render 'error'
      return
    end

    render('error') and return unless lti_authorize!

    lms_type = ensure_lms_type(params[:tool_consumer_info_product_family_code])
    if lms_type.blank?
      @message = 'OpenDSA requires that the request include the "tool_consumer_info_product_family_code" parameter'
      render 'error'
      return
    end

    email = params.key?(:lis_person_contact_email_primary) ?
      params[:lis_person_contact_email_primary] :
      params[:oauth_consumer_key]
    @user = User.where(email: email).first
    if @user.blank? || !@user.global_role.is_instructor_or_admin?
      @message = 'The email of your LMS account does not match an OpenDSA instructor account.'
      render 'error'
      return
    end
    sign_in @user

    @deep_linking = lms_type.name.downcase != 'canvas'
    lms_instance = ensure_lms_instance()
    @lms_course_num = get_lms_course_num(lms_type.name, lms_instance)
    @lms_course_code = params[:context_label]
    @lms_instance_id = lms_instance.id
    @organization_id = lms_instance.organization_id
    @course_offering = CourseOffering.find_by(
      lms_instance_id: lms_instance.id,
      lms_course_num: @lms_course_num,
    )
    if @course_offering.blank?
      if lms_instance.organization_id.blank?
        @organizations = Organization.all.order(:name)
      end
      @terms = Term.on_or_future.order(:starts_on)
    end

    @launch_url = request.protocol + request.host_with_port + "/lti/launch"

    require 'rst/rst_parser'
    exercises = RstParser.get_exercise_info()

    @json = exercises.to_json()

    render layout: 'lti_resource'
  end

  def content_item_selection
    if !user_signed_in? || !current_user.global_role.is_instructor_or_admin?
      render :json => {:status => 'fail', :message => 'You must be signed in as an instructor.'}.to_json,
        :status => :unauthorized
      return
    end

    consumer_key = params['oauth_consumer_key']
    $oauth_creds = LmsAccess.get_oauth_creds(consumer_key)
    consumer_secret = $oauth_creds[consumer_key]
    return_url = params[:content_item_return_url]

    content_item_params = {}
    content_item_params["lti_message_type"] = 'ContentItemSelection'
    content_item_params["lti_version"] = "LTI-1p0"
    content_item_params["content_items"] = params[:content_items]

    require 'lti/oauth'
    oauth_info = OAuth.generate_oauth_params(consumer_key, consumer_secret, return_url,
                                             content_item_params)

    render :json => oauth_info.as_json, :status => :ok
  end

  def launch_extrtool
    if current_user.blank?
      @message = "Error: current user could not be identified"
      render :error
      return
    end

    exercise = InstBookSectionExercise.includes(:inst_exercise, :inst_book, inst_book: [{course_offering: [:term, :course]}])
      .find_by(id: params[:inst_book_section_exercise_id])

    if exercise.blank?
      @message = "Error: could not locate exercise with id '#{params[:inst_book_section_exercise_id]}'"
      render :error
      return
    end

    course_offering = exercise.inst_book.course_offering

    unless course_offering.is_enrolled?(current_user)
      @message = 'Error: you are not enrolled in this course'
      render :error
      return
    end

    tool = LearningTool.find_by(name: exercise.inst_exercise.learning_tool)
    host = request.scheme + "://" + request.host_with_port

    @launch_url = tool.launch_url
    launch_params = {}
    launch_params["launch_url"] = @launch_url
    launch_params["context_label"] = course_offering.name
    launch_params["context_title"] = course_offering.name
    launch_params["context_id"] = "#{exercise.id}"
    launch_params["lis_outcome_service_url"] = "#{host}#{lti_grade_passback_path}"
    # we don't need/want scores for instructors
    unless course_offering.is_instructor?(current_user)
      launch_params["lis_result_sourcedid"] = "#{current_user.id}_#{exercise.id}"
    end
    launch_params["lti_message_type"] = "basic-lti-launch-request"
    launch_params["lti_version"] = "LTI-1p0"
    launch_params["resource_link_id"] = "#{exercise.id}"
    launch_params["resource_link_title"] = exercise.inst_exercise.short_name
    launch_params["tool_consumer_info_product_family_code"] = "opendsa"
    launch_params["user_id"] = "#{current_user.id}"
    launch_params["lis_person_name_given"] = current_user.first_name
    launch_params["lis_person_name_family"] = current_user.last_name
    launch_params["lis_person_contact_email_primary"] = current_user.email
    launch_params["ext_lti_assignment_id"] = "#{exercise.id}"
    launch_params["roles"] = get_user_lti_role(course_offering)
    launch_params["custom_course_name"] = course_offering.course.name
    launch_params["custom_course_number"] = course_offering.course.number
    launch_params["custom_label"] = course_offering.label
    launch_params["custom_term"] = course_offering.term.slug

    @tc = IMS::LTI::ToolConsumer.new(tool.key, tool.secret, launch_params)
    @launch_data = @tc.generate_launch_data()

    render 'launch_extrtool', layout: 'header_minimal'
  end

  def grade_passback
    req = IMS::LTI::OutcomeRequest.from_post_request(request)
    res = IMS::LTI::OutcomeResponse.new
    res.message_ref_identifier = req.message_identifier
    res.operation = req.operation
    res.severity = 'status'

    if req.replace_request?
      # set a new score for the user

      # lis_result_sourcedid is in format {user_id}_{inst_book_section_exercise_id}
      # (because that is how we sent it in the original launch request)
      tokens = req.lis_result_sourcedid.split("_")
      user_id = tokens[0]
      inst_book_section_exercise_id = tokens[1]
      score = Float(req.score.to_s)

      if score < 0.0 || score > 1.0
        res.description = "The score must be between 0.0 and 1.0"
        res.code_major = 'failure'
      else
        # we store exercise scores in the database as an integer
        score = Integer(score * 100)
        ex_progress = OdsaExerciseProgress.find_by(user_id: tokens[0],
                                                   inst_book_section_exercise_id: inst_book_section_exercise_id)
        if ex_progress.blank?
          ex_progress = OdsaExerciseProgress.new(user_id: tokens[0],
                                                 inst_book_section_exercise_id: inst_book_section_exercise_id)
        end
        old_score = ex_progress.current_score
        ex_progress.update_score(score)
        ex_progress.save!

        bk_sec_ex = InstBookSectionExercise.includes(:inst_exercise, inst_section: [:inst_chapter_module])
          .find_by(id: inst_book_section_exercise_id)
        inst_chapter_module = bk_sec_ex.inst_section.inst_chapter_module

        # update the score for the module containing the exercise
        mod_prog = OdsaModuleProgress.get_progress(user_id, inst_chapter_module.id, bk_sec_ex.inst_book_id)
        mod_prog.update_proficiency(bk_sec_ex.inst_exercise)

        res.description = "Your old score of #{old_score} has been replaced with #{score}"
        res.code_major = 'success'
      end
    elsif req.read_request?
      # return the score for the user
      tokens = req.lis_result_sourcedid.split("_")
      user_id = tokens[0]
      inst_book_section_exercise_id = tokens[1]
      progress = OdsaExerciseProgress.find_by(user_id: user_id,
                                              inst_book_section_exercise_id: inst_book_section_exercise_id)

      res.description = progress.blank? ? "Your score is 0" : "Your score is #{progress.current_score}"
      res.score = progress.current_score
      res.code_major = 'success'
    elsif req.delete_request?
      res.code_major = 'unsupported'
      res.description = "#{req.operation} is not supported"
    else
      res.severity = 'error'
      res.code_major = 'unsupported'
      res.description = "#{req.operation} is not supported"
    end

    xml = res.generate_response_xml
    render xml: xml
  end

  private

  def get_user_lti_role(course_offering)
    if course_offering.is_instructor?(current_user)
      return "Instructor"
    else
      return "Student"
    end
  end

  def launch_ex
    require 'oauth/request_proxy/rack_request'
    $oauth_creds = LmsAccess.get_oauth_creds(params[:oauth_consumer_key])
    lms_instance = ensure_lms_instance()
    lms_type_name = params[:tool_consumer_info_product_family_code].downcase
    lms_course_num = get_lms_course_num(lms_type_name, lms_instance)
    course_offering = CourseOffering.where(lms_course_num: lms_course_num,
                                           lms_instance_id: lms_instance.id).first

    render('error') and return unless lti_authorize!
    render('error') and return unless ensure_user(lms_instance.id)
    lti_enroll(course_offering)

    require 'rst/rst_parser'
    @ex = RstParser.get_exercise_map()[params[:ex_short_name]]
    @course_off_ex = InstCourseOfferingExercise.find_by(
      course_offering_id: course_offering.id,
      resource_link_id: params[:resource_link_id],
    )
    if @course_off_ex.blank?
      @course_off_ex = InstCourseOfferingExercise.new(
        course_offering: course_offering,
        inst_exercise_id: @ex.id,
        resource_link_id: params[:resource_link_id],
        resource_link_title: params[:resource_link_title],
        threshold: @ex.threshold,
      )
      @course_off_ex.save
    end

    if @ex.instance_of?(AvEmbed)
      render "launch_avembed", layout: 'lti_launch'
    else
      render 'launch_inlineav', layout: 'lti_launch'
    end
  end

  def ensure_lms_type(type_name)
    type_name.downcase!
    lms_type = LmsType.find_by('lower(name) = :name', name: type_name)
    if lms_type.blank?
      lms_type = LmsType.new(name: type_name)
      lms_type.save
    end
    return lms_type
  end

  def launch_instructor_tool
    if !user_signed_in? || !@course_offering.is_instructor?(current_user)
      @message = 'You must be signed in as an instructor for this course offering.'
      render 'error'
      return
    end

    @course_enrollment = CourseEnrollment.where("course_offering_id=?", @course_offering.id)
    @student_list = []
    @course_enrollment.each do |s|
      q = User.where("id=?", s.user_id).select("id, first_name, last_name").first
      @student_list.push(q)
      @student_list = @student_list.sort_by &:first_name
    end

    @course_id = @course_offering.id
    @instBook = @course_offering.odsa_books.first

    @chapter_list = InstChapter.includes(inst_chapter_modules: [:inst_module]).where("inst_book_id = ? AND inst_chapter_modules.lms_assignment_id IS NOT NULL", @instBook.id).references(:inst_chapter_modules)

    render 'show_table.html.haml' and return
  end

  def lti_enroll(course_offering)
    role = @tp.context_instructor? ? CourseRole.instructor : CourseRole.student
    if course_offering &&
       course_offering.can_enroll? &&
       !course_offering.is_enrolled?(current_user)
      CourseEnrollment.create(
        course_offering: course_offering,
        user: current_user,
        course_role: role,
      )
    elsif course_offering.is_enrolled?(current_user)
      # check if the user's course role has changed
      ce = CourseEnrollment.find_by(course_offering_id: course_offering.id,
                                    user_id: current_user.id)
      if ce.course_role != role
        # update user's course role
        ce.course_role = role
        ce.save!
      end
    end
  end

  def ensure_lms_instance
    uri = URI.parse(request.referrer)
    url = uri.scheme + '://' + uri.host
    lms_instance = LmsInstance.find_by(url: url)
    if lms_instance.blank?
      lms_instance = LmsInstance.new(
        url: url,
        lms_type: LmsType.find_by('lower(name) = :name', name: params[:tool_consumer_info_product_family_code].downcase),
      )
      lms_instance.save
    end
    return lms_instance
  end

  def ensure_user(lms_instance_id)
    email = params[:lis_person_contact_email_primary]
    if email.blank?
      # try to uniquely identify user some other way
      if params[:user_id].blank?
        @message = 'OpenDSA: Unable to uniquely identify user'
        return false
      end
      email = OpenDSA::STUDENT_VIEW_EMAIL
    end
    @user = User.where(email: email).first

    if @user.blank?
      # TODO: should mark this as LMS user then prevent this user from login to opendsa domain
      @user = User.new(:email => email,
                       :password => email,
                       :password_confirmation => email,
                       :first_name => params[:lis_person_name_given],
                       :last_name => params[:lis_person_name_family])
      unless @user.save
        @message = "OpenDSA: Failed to create user"
        error = Error.new(:class_name => 'user_create_fail',
                          :message => "Failed to create user #{email}", :params => params.to_s)
        error.save!
        return false
      end
    elsif @user.first_name != params[:lis_person_name_given] || @user.last_name != params[:lis_person_name_family]
      # update user's name
      @user.first_name = params[:lis_person_name_given]
      @user.last_name = params[:lis_person_name_family]
      @user.save
    end
    successful = sign_in @user
    unless successful
      @message = 'OpenDSA: sign-in failed'
      error = Error.new(:class_name => 'user_sign_in_fail',
                        :message => "Failed to sign in user #{email}", :params => params.to_s)
      error.save!
      return false
    end
    return true #successful
  end

  def lti_authorize!
    if $oauth_creds.blank?
      @message = "OpenDSA: No OAuth credentials found"
      return false
    elsif key = params['oauth_consumer_key']
      if secret = $oauth_creds[key]
        @tp = IMS::LTI::ToolProvider.new(key, secret, params)
      else
        @tp = IMS::LTI::ToolProvider.new(nil, nil, params)
        @tp.lti_msg = "Your consumer didn't use a recognized key."
        @tp.lti_errorlog = "You did it wrong!"
        @message = "OpenDSA: Consumer key wasn't recognized"
        return false
      end
    else
      @message = "No consumer key"
      return false
    end

    if !params.has_key?(:selection_directive)
      if !@tp.valid_request?(request)
        @message = "OpenDSA: The OAuth signature was invalid"
        return false
      end

      if Time.now.utc.to_i - @tp.request_oauth_timestamp.to_i > 60 * 60
        @message = "OpenDSA: Your request is too old."
        return false
      end

      # this isn't actually checking anything like it should, just want people
      # implementing real tools to be aware they need to check the nonce
      if was_nonce_used_in_last_x_minutes?(@tp.request_oauth_nonce, 60)
        @message = "OpenDSA: Why are you reusing the nonce?"
        return false
      end
    end
    return true
  end

  def get_lms_course_num(lms_type_name, lms_instance)
    if (lms_type_name.downcase == 'canvas')
      return params[:custom_canvas_course_id]
    else
      # generate a somewhat unique string to use as the course id
      return "#{lms_type_name}_#{lms_instance.id}_#{params[:context_label]}_#{params[:oauth_consumer_key]}"
    end
  end

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end

  def was_nonce_used_in_last_x_minutes?(nonce, minutes = 60)
    # some kind of caching solution or something to keep a short-term memory of used nonces
    false
  end

  def ensure_course_offering(lms_instance_id, organization_id, lms_course_num, lms_course_code, course_name)
    course_offering = CourseOffering.find_by(lms_instance_id: lms_instance_id,
                                             lms_course_num: lms_course_num)
    if course_offering.blank?
      if organization_id.blank?
        return nil
      end
      course = Course.find_by(number: lms_course_code,
                              organization_id: organization_id)
      if course.blank?
        course = Course.new(
          name: course_name,
          number: lms_course_code,
          organization_id: organization_id,
          user_id: current_user.id,
        )
        course.save
      end
      course_offering = CourseOffering.new(
        course: course,
        term: Term.current_or_next_term,
        label: lms_course_code,
        lms_instance_id: lms_instance_id,
        lms_course_code: lms_course_code,
        lms_course_num: lms_course_num,
      )
      course_offering.save
    end
    return course_offering
  end

  def ensure_module_progress(lms_access_id)
    book_id = params[:custom_inst_book_id]
    chpt_mod_id = params[:custom_inst_chapter_module_id]
    OdsaModuleProgress.get_progress(current_user.id, chpt_mod_id, book_id,
                                    params[:lis_outcome_service_url],
                                    params[:lis_result_sourcedid],
                                    lms_access_id)
  end
end
