class LtiController < ApplicationController
  #require 'data_table'
  layout 'lti', only: [:launch]

  after_action :allow_iframe, only: :launch
  # the consumer keys/secrets

  def launch
    # must include the oauth proxy object
    require 'oauth/request_proxy/rack_request'
    @inst_book = InstBook.find_by(id: params[:custom_inst_book_id])
    $oauth_creds = @inst_book.lms_creds

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

    @section_html = File.read(File.join('public/OpenDSA/Books',
                                                            params[:custom_book_path],
                                                            '/lti_html/', "#{params[:custom_section_file_name].to_s}.html")) and return
  end

  def assessment
    puts "You done &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
    #puts "reps"
    request_params = JSON.parse(request.body.read.to_s)
    inst_book_id = request_params['instBookId']
    inst_bk_sec_ex_id = request_params['instBookSectionExerciseId']

    @inst_book = InstBook.find_by(id: inst_book_id)

    #my code

    @odsa_exercise_attempts = OdsaExerciseAttempt.find_by(:inst_book_id == @inst_book)

    e = @odsa_exercise_attempts.count_hints
    puts "number of attemp is #{e}"
    c = @odsa_exercise_attempts.request_type
    puts "request type: #{c}"
    d = @odsa_exercise_attempts.count_hints
    puts "hint count num is: #{d}"
    d = @odsa_exercise_attempts.count_attempts
    puts "count attemp is: #{d}"
    d = @odsa_exercise_attempts.question_name
    puts "question_name is: #{d}"
    d = @odsa_exercise_attempts.correct
    puts "correct is: #{d}"
    d = @odsa_exercise_attempts.points_earned
    puts "points_earned: #{d}"
    d = @odsa_exercise_attempts.earned_proficiency
    puts "earned_proficiency: #{d}"
    d = @odsa_exercise_attempts.user_id
    puts "user_id: #{d}"

    @odsa_exercise_progress = OdsaExerciseProgress.find_by(id: d)
    t = @odsa_exercise_progress.current_score
    puts "current_score: #{t}"
    t = @odsa_exercise_progress.highest_score
    puts "highest_score: #{t}"
    t = @odsa_exercise_progress.first_done
    puts "first_done: #{t}"
    t = @odsa_exercise_progress.last_done
    puts "last_done: #{t}"
    t = @odsa_exercise_progress.total_correct
    puts "total_correct: #{t}"
    puts "seeting variable"
    a = @odsa_exercise_attempts
    b = @odsa_exercise_progress
    puts "now data"
    #data = DataTb.new(a, b)
    #puts "after data"
    puts "start render_to_string"
    TableHelper.arg(a, b)
    f = render_to_string "lti/table.html.erb"
    puts f

    


    #end




    $oauth_creds = @inst_book.lms_creds
    launch_params = request_params['toParams']['launch_params']
    if launch_params
      key = launch_params['oauth_consumer_key']
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
    #     # add extension
    @tp.extend IMS::LTI::Extensions::OutcomeData::ToolProvider

    if !@tp.outcome_service?
      @message = "This tool wasn't lunched as an outcome service"
      render(:error)
    end

    # post the given score to the TC
    score = (request_params['toParams']['score'] != '' ? request_params['toParams']['score'] : nil)
    
    #me
    res = nil

    #p @tp.accepted_outcome_types

    if @tp.accepts_outcome_url?
      puts "accept text"
      res = @tp.post_extended_replace_result!(score: score, text: f)
    elsif @tp.accepts_outcome_data?
      puts "accept data"
    elsif @tp.accepts_outcome_data?
      puts "accept data"
    else
      puts "no text"
      res = @tp.post_extended_replace_result!(score: score, text: f)
      #res = @tp.post_replace_result!(score)
    end
    #     if response.success?
    #       # grade write worked
    #     elsif response.processing?
    #     elsif response.unsupported?
    #     else
    #       # failed
    #     end


    #end of my code
    #res = @tp.post_replace_result!(score)

    #end
    if res.success?
      # @score = request_params['score']
      # @tp.lti_msg = "Message shown when arriving back at Tool Consumer."
      render :json => { :message => 'success', :res => res.to_json }.to_json
      # error = Error.new(:class_name => 'post_replace_result_success', :message => res.inspect, :params => lti_param.to_s)
      # error.save!
      # erb :assessment_finished
    else
      render :json => { :message => 'failure', :res => res.to_json }.to_json
      error = Error.new(:class_name => 'post_replace_result_fail', :message => res.inspect, :params => lti_param.to_s)
      error.save!
      # @tp.lti_errormsg = "The Tool Consumer failed to add the score."
      # show_error "Your score was not recorded: #{res.description}"
      # return erb :error
    end

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

      # @username = @tp.username("Dude")
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
