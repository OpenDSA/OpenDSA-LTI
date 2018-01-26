class LtiController < ApplicationController
  layout 'lti', only: [:launch]

  after_action :allow_iframe, only: [:launch, :resource]
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
    # TODO: get user info from @tp object
    # register the user if he is not yet registered.
    ensure_user()
    lti_enroll(@course_offering)

    # I change this to be custom intanbook id becuase it is not working on mine yet
    if params.has_key?(:custom_course_offering_id)

      puts ('param have key')

      @course_enrollment = CourseEnrollment.where("course_offering_id=?", @course_offering.id)
      @student_list = []
      @course_enrollment.each do |s|
        q = User.where("id=?", s.user_id).select("id, first_name, last_name").first
        @student_list.push(q)
      #puts "helloo"
      @student_list = @student_list.sort_by &:first_name
      end
      
      @course_id =  @course_offering.id
      @instBook = @course_offering.odsa_books.first
      
      @exercise_list = Hash.new{|hsh,key| hsh[key] = []}

      chapters = InstChapter.where(inst_book_id: @instBook.id).order('position')
      chapters.each do |chapter|
        modules = InstChapterModule.where(inst_chapter_id: chapter.id).order('module_position')
        modules.each do |inst_ch_module|
          sections = InstSection.where(inst_chapter_module_id: inst_ch_module.id)
          section_item_position = 1
          if !sections.empty?
            sections.each do |section|
              title = (chapter.position.to_s.rjust(2, "0")||"") + "." +
                      (inst_ch_module.module_position.to_s.rjust(2, "0")||"") + "." +
                      section_item_position.to_s.rjust(2, "0") + " - "
              learning_tool = nil
              if section
                title = title + section.name
                learning_tool = section.learning_tool
                if !learning_tool
                  if section.gradable
                    attempted = OdsaExerciseAttempt.where(inst_section_id: section.id)
                    if attempted.empty?
                      @exercise_list[section.id].push(title)
                    else
                      @exercise_list[section.id].push(title)
                      @exercise_list[section.id].push('attemp_flag')
                    end
                  end
                end
              end
              section_item_position += 1
            end
          end
        end
      end
      render 'show_table.html.haml' and return
    end

    @section_html = File.read(File.join('public/OpenDSA/Books',
                              params[:custom_book_path],
                              '/lti_html/',
                              "#{params[:custom_section_file_name].to_s}.html")) and return
  end

  def assessment
    request_params = JSON.parse(request.body.read.to_s)
    hasBook = request_params.key?('instBookId')

    if hasBook
      inst_section = InstSection.find_by(id: request_params['instSectionId'])
      
      @odsa_exercise_attempts = OdsaExerciseAttempt.where("inst_book_section_exercise_id=? AND user_id=?",
                                  request_params['instBookSectionExerciseId'], current_user.id).select(
                                  "id, user_id, question_name, request_type,
                                  correct, worth_credit, time_done, time_taken, earned_proficiency, points_earned,
                                  pe_score, pe_steps_fixed")
      @odsa_exercise_progress = OdsaExerciseProgress.where("inst_book_section_exercise_id=? AND user_id=?",
                                  request_params['instBookSectionExerciseId'], current_user.id).select("user_id, current_score, highest_score,
                                  total_correct, proficient_date,first_done, last_done")
    else
      @odsa_exercise_attempts = OdsaExerciseAttempt.where("inst_course_offering_exercise_id=? AND user_id=?",
                                  request_params['instCourseOfferingExerciseId'], current_user.id).select(
                                  "id, user_id, question_name, request_type,
                                  correct, worth_credit, time_done, time_taken, earned_proficiency, points_earned,
                                  pe_score, pe_steps_fixed")
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
      "lis_result_sourcedid" => "#{launch_params['lis_result_sourcedid']}"
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
    #res = @tp.post_replace_result!(score)
    res = @tp.post_extended_replace_result!(score: score, text: f)

    if res.success?
      if hasBook
        inst_section.lms_posted = true
        inst_section.time_posted = Time.now
        inst_section.save!
      end
      render :json => { :message => 'success', :res => res.to_json }.to_json
    else
      if hasBook
        inst_section.lms_posted = false
        inst_section.save!
      end
      render :json => { :message => 'failure', :res => res.to_json }.to_json, :status => :bad_request
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
      :selection_height => 600
    })

    tc.set_canvas_ext_param(:custom_fields, {
      canvas_api_base_url: '$Canvas.api.baseUrl'
    })

    render xml: tc.to_xml(:indent => 2), :content_type => 'text/xml'
  end

  def resource
    lms_type = params[:tool_consumer_info_product_family_code].downcase
    unless lms_type == 'canvas'
      @message = "#{lms_type} is not supported"
      render('error') and return
    end

    lms_instance = ensure_lms_instance()
    @lms_course_num = params[:custom_canvas_course_id]
    @lms_course_code = params[:context_label]
    @lms_instance_id = lms_instance.id
    @organization_id = lms_instance.organization_id
    @course_offering = CourseOffering.find_by(lms_instance_id: lms_instance.id, lms_course_num: @lms_course_num)
    if @course_offering.blank?
      if lms_instance.organization_id.blank?
        @organizations = Organization.all.order(:name)
      end
      @terms = Term.on_or_future.order(:starts_on)
    end
    
    @launch_url = request.protocol + request.host_with_port + "/lti/launch"

    # must include the oauth proxy object
    require 'oauth/request_proxy/rack_request'
    $oauth_creds = LmsAccess.get_oauth_creds(params[:oauth_consumer_key])

    render('error') and return unless lti_authorize!

    @user = User.where(email: params[:lis_person_contact_email_primary]).first
    sign_in @user

    require 'RST/rst_parser'
    exercises = RstParser.get_exercise_info()

    @json = exercises.to_json()

    render layout: 'lti_resource'
  end

  private

    def launch_ex
      require 'oauth/request_proxy/rack_request'
      $oauth_creds = LmsAccess.get_oauth_creds(params[:oauth_consumer_key])
      course_offering = CourseOffering.joins(:lms_instance).where(
        lms_instances: {url: params[:custom_canvas_api_base_url]}, 
        course_offerings: {lms_course_num: params[:custom_canvas_course_id]}
      ).first

      render('error') and return unless lti_authorize!
      ensure_user()
      lti_enroll(course_offering)

      require 'RST/rst_parser'
      @ex = RstParser.get_exercise_map()[params[:ex_short_name]]
      @course_off_ex = InstCourseOfferingExercise.find_by(
        course_offering_id: course_offering.id, 
        resource_link_id: params[:resource_link_id]
      )
      if @course_off_ex.blank?
        @course_off_ex = InstCourseOfferingExercise.new(
          course_offering: course_offering,
          inst_exercise_id: @ex.id,
          resource_link_id: params[:resource_link_id],
          resource_link_title: params[:resource_link_title],
          threshold: @ex.threshold
        )
        @course_off_ex.save
      end

      if @ex.instance_of?(AvEmbed)
        render "launch_avembed", layout: 'lti_launch'
      else
        render 'launch_inlineav', layout: 'lti_launch'
      end
    end

    def lti_enroll(course_offering, role = CourseRole.student)
      if course_offering &&
        course_offering.can_enroll? &&
        !course_offering.is_enrolled?(current_user)

        CourseEnrollment.create(
          course_offering: course_offering,
          user: current_user,
          course_role: role)
      end
    end

    def lti_authorize!
      if key = params['oauth_consumer_key']
        if secret = $oauth_creds[key]
          @tp = IMS::LTI::ToolProvider.new(key, secret, params)
        else
          @tp = IMS::LTI::ToolProvider.new(nil, nil, params)
          @tp.lti_msg = "Your consumer didn't use a recognized key."
          @tp.lti_errorlog = "You did it wrong!"
          @message = "Consumer key wasn't recognized"
          return false
        end
      else
        render("No consumer key")
        return false
      end

      if !params.has_key?(:selection_directive)
        if !@tp.valid_request?(request)
          @message = "The OAuth signature was invalid"
          return false
        end

        if Time.now.utc.to_i - @tp.request_oauth_timestamp.to_i > 60*60
          @message = "Your request is too old."
          return false
        end

        # this isn't actually checking anything like it should, just want people
        # implementing real tools to be aware they need to check the nonce
        if was_nonce_used_in_last_x_minutes?(@tp.request_oauth_nonce, 60)
          @message = "Why are you reusing the nonce?"
          return false
        end
      end

      return true
    end

    def allow_iframe
      response.headers.except! 'X-Frame-Options'
    end

    def was_nonce_used_in_last_x_minutes?(nonce, minutes=60)
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
        course = Course.where(number: lms_course_code, 
          organization_id: organization_id).first
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
          lms_course_num: lms_course_num)
        course_offering.save
      end
      return course_offering
    end

    def ensure_lms_instance
      lms_instance = LmsInstance.find_by(url: params[:custom_canvas_api_base_url])
      if lms_instance.blank?
        lms_instance = LmsInstance.new(
          url: params[:custom_canvas_api_base_url],
          lms_type: LmsType.find_by('lower(name) = :name', name: params[:tool_consumer_info_product_family_code]),
        )
        lms_instance.save
      end
      return lms_instance
    end

    def ensure_user
      email = params[:lis_person_contact_email_primary]
      @user = User.where(email: email).first
      if @user.blank?
        # TODO: should mark this as LMS user then prevent this user from login to opendsa domain
        @user = User.new(:email => email,
                         :password => email,
                         :password_confirmation => email,
                         :first_name => params[:lis_person_name_given],
                         :last_name => params[:lis_person_name_family])
        @user.save
      end
      sign_in @user
    end

end
