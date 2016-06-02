class LtiController < ApplicationController
layout 'lti', only: [:launch]

  after_action :allow_iframe, only: :launch
  # the consumer keys/secrets

  def user_interaction

    require "rubygems"
    require "json"

    # string = '{"desc":{"someKey":"someValue","anotherKey":"value"},"main_item":{"stats":{"a":8,"b":12,"c":10}}}'
    parsed = JSON.parse(uinteraction) # returns a hash

    # uid = parsed["desc"]["someKey"]

    ibookid = parsed["uinteraction"]["inst_book_id"]
    uid = parsed["uinteraction"]["user_id"]
    isecid = parsed["uinteraction"]["inst_section_id"]
    ibseid = parsed["uinteraction"]["inst_book_section_exercise_id"]
    name = parsed["uinteraction"]["name"]
    desc = parsed["uinteraction"]["description"]
    actime = parsed["uinteraction"]["action_time"]
    uiid = parsed["uinteraction"]["uiid"]
    bfamily = parsed["uinteraction"]["browser_family"]
    bversion = parsed["uinteraction"]["browser_version"]
    ofamily = parsed["uinteraction"]["os_family"]
    oversion = parsed["uinteraction"]["os_version"]
    device = parsed["uinteraction"]["device"]
    ip = parsed["uinteraction"]["ip_address"]
    create = parsed["uinteraction"]["created_at"]
    update = parsed["uinteraction"]["updated_at"]

    # puts uid
    # render(:launch)
    user_interaction = OdsaUserInteraction.create(inst_book_id: "#{ibookid}", user_id: "#{uid}", inst_section_id: "#{isecid}", inst_book_section_exercise_id: "#{ibseid}", name: "#{name}",
    description: "#{desc}", action_time: "#{actime}", uiid: "#{uiid}",
    browser_family: "#{bfamily}", browser_version: "#{bversion}", os_family: "#{ofamily}", os_version: "#{oversion}", device: "#{device}",
    ip_address: "#{ip}", created_at: "#{create}", updated_at: "#{update}")

  end

  after_save :exercise_attempts
  def exercise_attempts

    require "rubygems"
    require "json"

    # string = '{"desc":{"someKey":"someValue","anotherKey":"value"},"main_item":{"stats":{"a":8,"b":12,"c":10}}}'
    parsed = JSON.parse(exe_attempt) # returns a hash

    # uid = parsed["desc"]["someKey"]

    uid = parsed["exe_attempt"]["user_id"]
    bsid = parsed["exe_attempt"]["inst_book_section_exercise_id"]
    imoid = parsed["exe_attempt"]["inst_module_id"]
    correct = parsed["exe_attempt"]["correct"]
    time_d = parsed["exe_attempt"]["time_done"]
    time_t = parsed["exe_attempt"]["time_taken"]
    hints = parsed["exe_attempt"]["count_hints"]
    hintsu = parsed["exe_attempt"]["hint_used"]
    points = parsed["exe_attempt"]["points_earned"]
    proficiency = parsed["exe_attempt"]["earned_proficiency"]
    attempts = parsed["exe_attempt"]["count_attempts"]
    ip = parsed["exe_attempt"]["ip_address"]
    ex = parsed["exe_attempt"]["ex_question"]
    create = parsed["exe_attempt"]["created_at"]
    update = parsed["exe_attempt"]["updated_at"]

    # puts "update"
    # puts uid
    # render(:launch)

    ex_attempt = OdsaExerciseAttempt.new(user_id: "#{uid}", inst_book_section_exercise_id: "#{bsid}", correct: "#{correct}", time_done: "#{time_d}", time_taken: "#{time_t}", count_hints: "#{hints}", hint_used: "#{hintsu}", points_earned: "#{points}", earned_proficiency: "#{proficiency}",
    count_attempts: "#{attempts}", ip_address: "#{ip}", ex_question: "#{ex}", created_at: "#{create}", updated_at: "#{update}")

    ex_attempt.save

    #exercise_progress operation starts

    if OdsaExerciseProgress.exists?(user_id: "#{uid}", inst_book_section_exercise_id: "#{bsid}")

      if correct == 1
        user_progress = OdsaExerciseProgress.where(user_id: "#{uid}", inst_book_section_exercise_id: "#{bsid}")

        user_progress.increment!(:streak, by = 1)
        lstreak = user_progress.maximum("streak")
        user_progress.update!(:longest_streak, "#{lstreak}")
        user_progress.update!(:last_done, "#{time_d}")
        user_progress.increment!(:total_done, by = 1)
        user_progress.increment!(:total_correct, by = 1)
        user_progress.update!(:updated_at, "#{update}")
        progress = user_progress.streak.to_f / user_progress.inst_book_section_exercise.streak

        if proficiency == 1
          pdate = time_d
        else
          pdate = nil
        end

      else
        user_progress.update!(:last_done, "#{time_d}")
        user_progress.increment!(:total_done, by = 1)
        user_progress.update!(:updated_at, "#{update}")

        if user_progress.streak - 1 >0
          user_progress.decrement!(:streak, by = 1)
        else
          user_progress.update!(:streak, 0)
        end

        progress = user_progress.streak.to_f / user_progress.inst_book_section_exercise.streak

      end

    else

      if correct == 1

        streak = 1
        lstreak = 1
        tdone = 1
        tcorrect = 1

        if proficiency == 1
          pdate = time_d
        else
          pdate = nil
        end

        progress = user_progress.streak.to_f / user_progress.inst_book_section_exercise.streak

        user_progress = OdsaExerciseProgress.create(user_id: "#{uid}", streak: "#{streak}", longest_streak: "#{lstreak}",
        first_done: "#{time_d}", last_done: "#{time_d}", total_done: "#{tdone}",
        total_correct: "#{tcorrect}", proficient_date: "#{pdate}", progress: "#{progress}",
        inst_book_section_exercise_id: "#{bsid}",
        created_at: "#{time_d}", updated_at: "#{time_d}")

      else
        streak = 0
        lstreak = 0
        tdone = 1
        tcorrect = 0
        pdate = nil

        progress = user_progress.streak.to_f / user_progress.inst_book_section_exercise.streak

        user_progress = OdsaExerciseProgress.create(user_id: "#{uid}", streak: "#{streak}", longest_streak: "#{lstreak}",
        first_done: "#{time_d}", last_done: "#{time_d}", total_done: "#{tdone}",
        total_correct: "#{tcorrect}", proficient_date: "#{pdate}", progress: "#{progress}",
        inst_book_section_exercise_id: "#{bsid}",
        created_at: "#{time_d}", updated_at: "#{time_d}")


      end


    end

    # OdsaExerciseProgress.create_with(streak: "#{streak}", longest_streak: "#{lstreak}",
    # first_done: "#{fdone}", last_done: "#{ldone}", total_done: "#{tdone}",
    # total_correct: "#{tcorrect}", proficient_date: "#{pdate}", progress: "#{progress}",
    # inst_book_section_exercise_id: "#{ibsid}",
    # created_at: "#{create}", updated_at: "#{update}").find_or_create_by(user_id: "#{uid}")

    #module_progress operation starts

    book_search = OdsaExerciseProgress.where(inst_book_section_exercise_id: "#{bsid}")
    book_id = book_search.inst_book_section_exercise.inst_book[:id]

    if OdsaModuleProgress.exists?(user_id: "#{uid}", inst_book_id: "#{book_id}", inst_module_id: "#{imoid}")

      module_progress = OdsaModuleProgress.where(user_id: "#{uid}", inst_book_id: "#{book_id}", inst_module_id: "#{imoid}")

      pdate = OdsaExerciseProgress.where(user_id: "#{uid}", inst_book_id: "#{book_id}", inst_module_id: "#{imoid}").proficient_date

      module_progress.update!(:last_done, "#{time_d}")
      module_progress.update!(:proficient_date, "#{pdate}")
      module_progress.update!(:updated_at, "#{time_d}")


    else
      pdate = nil

      user_module = OdsaModuleProgress.create(user_id: "#{uid}", inst_book_id: "#{book_id}", inst_module_id: "#{imoid}",
      first_done: "#{time_d}", last_done: "#{time_d}",
      proficient_date: "#{pdate}", created_at: "#{time_d}", updated_at: "#{time_d}")
    end


  end


  def launch
    # must include the oauth proxy object
    require 'oauth/request_proxy/rack_request'
    @inst_book = InstBook.find_by(id: params[:inst_book_id])
    $oauth_creds = @inst_book.lms_creds

    render('error') and return unless lti_authorize!

    # TODO: get user info from @tp object
    # register the user if he is not yet registered.
    email = params[:lis_person_contact_email_primary]
    first_name = params[:lis_person_name_given]
    last_name = params[:lis_person_name_family]
    @user = User.where(email: email).first
    if @user.blank?
      # TODO: should mark this as LMS user then prevent this user from login to codeworkout domain
      @user = User.new(:email => email, :password => email, :password_confirmation => email, :first_name => first_name, :last_name => last_name)
      @user.save
    end
    sign_in @user
    lti_enroll

    @section_html = File.read(File.join('public/OpenDSA/Books',
                                                            params["book_path"],
                                                            '/lti_html/', "#{params['section_file_name'].to_s}.html")) and return

  end

  def assessment
    request_params = JSON.parse(request.body.read.to_s)
    launch_params = request_params['launch_params']
    if launch_params
      key = launch_params['oauth_consumer_key']
    else
      @message = "The tool never launched"
      render(:error)
    end

    @tp = IMS::LTI::ToolProvider.new(key, $oauth_creds[key], launch_params)

    if !@tp.outcome_service?
      @message = "This tool wasn't lunched as an outcome service"
      render(:error)
    end

    # post the given score to the TC
    score = (request_params['score'] != '' ? request_params['score'] : nil)
    res = @tp.post_replace_result!(score)

    if res.success?
      # @score = request_params['score']
      # @tp.lti_msg = "Message shown when arriving back at Tool Consumer."
      render :json => { :message => 'success' }.to_json
      # erb :assessment_finished
    else
      render :json => { :message => 'failure' }.to_json
      # @tp.lti_errormsg = "The Tool Consumer failed to add the score."
      # show_error "Your score was not recorded: #{res.description}"
      # return erb :error
    end
  end

  private
    def lti_enroll
      inst_book = InstBook.find_by(id: params[:inst_book_id])
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
