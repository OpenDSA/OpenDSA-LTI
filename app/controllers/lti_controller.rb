class LtiController < ApplicationController
  layout 'lti', only: [:launch]

  after_action :allow_iframe, only: [:launch, :resource]
  # the consumer keys/secrets

  def launch
    # must include the oauth proxy object
    require 'oauth/request_proxy/rack_request'
    @inst_book = InstBook.find_by(id: params[:custom_inst_book_id])
    @course_offering = CourseOffering.find_by(id: @inst_book.course_offering_id)
    $oauth_creds = LmsAccess.get_oauth_creds(params[:oauth_consumer_key])

    render('error') and return unless lti_authorize!
    # TODO: get user info from @tp object
    # register the user if he is not yet registered.
    email = params[:lis_person_contact_email_primary]
    first_name = params[:lis_person_name_given]
    last_name = params[:lis_person_name_family]
    @user = User.where(email: email).first
    if @user.blank?
      # TODO: should mark this as LMS user then prevent this user from login to opendsa domain
      @user = User.new(:email => email,
                       :password => email,
                       :password_confirmation => email,
                       :first_name => first_name,
                       :last_name => last_name)
      @user.save
    end
    sign_in @user
    lti_enroll

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
    @inst_book = InstBook.find_by(id: request_params['instBookId'])
    @inst_section = InstSection.find_by(id: request_params['instSectionId'])
    inst_book_sect_exe_id = request_params['instBookSectionExerciseId']
    @inst_book_section_exercise_id = InstBookSectionExercise.find_by(id:inst_book_sect_exe_id)

    @current_user = User.where("email=?", request_params['userEmail']).select("id")
    @num = 0
    @current_user.collect! do |d|
      d.attributes.each do |x, y|
        @num = y
      end
    end

    @odsa_exercise_attempts = OdsaExerciseAttempt.where("inst_book_section_exercise_id=? AND user_id=?",
                                 request_params['instBookSectionExerciseId'], @num).select(
                                 "id, user_id, question_name, request_type,
                                 correct, worth_credit, time_done, time_taken, earned_proficiency, points_earned,
                                 pe_score, pe_steps_fixed")
    @odsa_exercise_progress = OdsaExerciseProgress.where("inst_book_section_exercise_id=? AND user_id=?",
                                 request_params['instBookSectionExerciseId'], @num).select("user_id, current_score, highest_score,
                                 total_correct, proficient_date,first_done, last_done")

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
      @inst_section.lms_posted = true
      @inst_section.time_posted = Time.now
      render :json => { :message => 'success', :res => res.to_json }.to_json
    else
      @inst_section.lms_posted = false
      render :json => { :message => 'failure', :res => res.to_json }.to_json
      error = Error.new(:class_name => 'post_replace_result_fail', :message => res.inspect, :params => lti_param.to_s)
      error.save!
    end
    @inst_section.save!
  end

  def xml_config
    host = request.scheme + "://" + request.host_with_port
    tc = IMS::LTI::ToolConfig.new(:title => "openDSA Tool Provider", :launch_url => host + '/lti/launch')
    tc.extend IMS::LTI::Extensions::Canvas::ToolConfig
    tc.description = "OpenDSA LTI Tool Provider supports LIS Outcome pass-back."
    tc.canvas_privacy_public!
    tc.canvas_resource_selection!({:url => host + '/lti/resource'})

    render xml: tc.to_xml(:indent => 2), :content_type => 'text/xml'
  end

  def resource
    @inst_book = InstBook.where("book_type = ?", InstBook.book_types[:Exercises]).first
    @launch_url = request.protocol + request.host_with_port + "/lti/launch"

    # must include the oauth proxy object
    require 'oauth/request_proxy/rack_request'
    $oauth_creds = LmsAccess.get_oauth_creds(params[:oauth_consumer_key])

    render('error') and return unless lti_authorize!

    email = params[:lis_person_contact_email_primary]
    first_name = params[:lis_person_name_given]
    last_name = params[:lis_person_name_family]
    @user = User.where(email: email).first
    sign_in @user

    @inst_book_json = ApplicationController.new.render_to_string(
        template: 'inst_books/show.json.jbuilder',
        locals: {:@inst_book => @inst_book})

    render layout: 'lti_resource'
  end

  def resource_dev
    @inst_book = InstBook.where("book_type = ?", InstBook.book_types[:Exercises]).first
    @launch_url = request.protocol + request.host_with_port + "/lti/launch"
    @inst_book_json = ApplicationController.new.render_to_string(
        template: 'inst_books/show.json.jbuilder',
        locals: {:@inst_book => @inst_book})

    render layout: 'lti_resource'
  end

  private
    def lti_enroll
      inst_book = InstBook.find_by(id: params[:custom_inst_book_id])
      course_offering = CourseOffering.find_by(id: inst_book.course_offering_id)

      if course_offering &&
        course_offering.can_enroll? &&
        !course_offering.is_enrolled?(current_user)

        CourseEnrollment.create(
        course_offering: course_offering,
        user: current_user,
        course_role: CourseRole.student)
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

end
