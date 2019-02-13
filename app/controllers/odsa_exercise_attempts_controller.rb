class OdsaExerciseAttemptsController < ApplicationController
  # load_and_authorize_resource

  #~ Action methods ...........................................................

  # -------------------------------------------------------------
  # POST /odsa_exercise_attempts
  def create
    unless user_logged_in?
      return
    end

    hasBook = params.key?(:inst_book_id)
    inst_exercise = nil
    if params.key?(:sha1)
      inst_exercise = InstExercise.find_by(short_name: params[:sha1])
    end
    if hasBook
      inst_book = InstBook.find_by(id: params[:inst_book_id])
      inst_section = nil
      inst_book_section_exercise = nil
      if params.key?(:inst_book_section_exercise_id)
        inst_book_section_exercise = InstBookSectionExercise.includes(:inst_exercise, :inst_section).find(params[:inst_book_section_exercise_id])
        inst_section = inst_book_section_exercise.inst_section
        inst_exercise = inst_book_section_exercise.inst_exercise
      else
        inst_section = InstSection.find_by(id: params[:inst_section_id])
        inst_book_section_exercise = InstBookSectionExercise.where(
          "inst_book_id=? and inst_section_id=? and inst_exercise_id=?",
          params[:inst_book_id], params[:inst_section_id], inst_exercise.id
        ).first
      end
      threshold = inst_book_section_exercise.threshold

      unless exercise_progress = OdsaExerciseProgress.where("user_id=? and inst_book_section_exercise_id=?",
                                                            current_user.id,
                                                            inst_book_section_exercise.id).first
        exercise_progress = OdsaExerciseProgress.new(user: current_user,
                                                     inst_book_section_exercise: inst_book_section_exercise)
        exercise_progress.save
      end
    else
      inst_course_offering_exercise = InstCourseOfferingExercise.find_by(
        id: params[:inst_course_offering_exercise_id],
      )
      threshold = inst_course_offering_exercise.threshold

      unless exercise_progress = OdsaExerciseProgress.find_by(user_id: current_user.id,
                                                              inst_course_offering_exercise_id: inst_course_offering_exercise.id)
        exercise_progress = OdsaExerciseProgress.new(user: current_user,
                                                     inst_course_offering_exercise: inst_course_offering_exercise)
        exercise_progress.save
      end
    end

    already_proficient = exercise_progress.proficient?

    question_name = params['problem_type']
    if params[:non_summative]
      question_name = params[:non_summative]
    end
    if params[:attempt_content] == "hint"
      request_type = "hint"
    else
      request_type = "attempt"
    end

    worth_credit = (params[:complete].to_i == 1 and params[:count_hints].to_i == 0 and params[:attempt_number].to_i == 1)

    if inst_exercise.short_name.include? "Summ"
      if (exercise_progress['hinted_exercise'].to_s == question_name.to_s)
        worth_credit = false
      end
    end

    exercise_attempt = OdsaExerciseAttempt.new(
      inst_book: inst_book,
      user: current_user,
      inst_section: inst_section,
      inst_book_section_exercise: inst_book_section_exercise,
      inst_course_offering_exercise: inst_course_offering_exercise,
      worth_credit: worth_credit,
      correct: params[:complete],
      time_done: Time.now,
      time_taken: params[:time_taken],
      count_hints: params[:count_hints],
      count_attempts: params[:attempt_number],
      hint_used: params[:count_hints].to_i > 0,
      question_name: question_name,
      request_type: request_type,
      ip_address: request.ip,
    )

    respond_to do |format|
      if exercise_attempt.save
        if hasBook
          exercise_progress = OdsaExerciseProgress.where(
            "user_id=? and inst_book_section_exercise_id=?",
            current_user.id,
            inst_book_section_exercise.id
          ).first
        else
          exercise_progress = OdsaExerciseProgress.find_by(user_id: current_user.id,
                                                           inst_course_offering_exercise_id: inst_course_offering_exercise.id)
        end

        format.json {
          render :json => {
                   :exercise_progress => exercise_progress,
                   :threshold => threshold,
                   :was_proficient => already_proficient,
                   :is_proficient => exercise_progress.proficient?,
                 }
        }
      else
        msg = {:status => "fail", :message => exercise_attempt.errors.full_messages}
        format.json { render :json => msg, :status => :bad_request }
        error = Error.new(:class_name => 'exercise_attempt_save_fail',
                          :message => exercise_attempt.errors.full_messages.inspect,
                          :params => params.to_s)
        error.save!
      end
    end
  end

  # -------------------------------------------------------------
  # POST /odsa_exercise_attempts/pe
  def create_pe
    unless user_logged_in?
      return
    end

    hasBook = params.key?(:inst_book_id)

    if params.key?(:inst_book_section_exercise_id)
      inst_book_section_exercise = InstBookSectionExercise.find(params[:inst_book_section_exercise_id])
      threshold = inst_book_section_exercise.threshold
    elsif hasBook
      inst_book = InstBook.find_by(id: params[:inst_book_id])
      inst_exercise = InstExercise.find_by(short_name: params[:exercise])
      inst_section = InstSection.find_by(id: params[:inst_section_id])
      inst_book_section_exercise = InstBookSectionExercise.where(
        "inst_book_id=? and inst_section_id=? and inst_exercise_id=?",
        params[:inst_book_id], params[:inst_section_id], inst_exercise.id
      ).first
      if inst_book_section_exercise.blank?
        respond_to do |format|
          msg = {:status => "fail", :message => "Fail!"}
          format.json { render :json => msg }
        end
        return
      end
      threshold = inst_book_section_exercise.threshold
    else
      inst_course_offering_exercise = InstCourseOfferingExercise.find_by(
        id: params[:inst_course_offering_exercise_id],
      )
      threshold = inst_course_offering_exercise.threshold
    end

    if inst_book_section_exercise != nil or inst_course_offering_exercise != nil
      if hasBook
        unless exercise_progress = OdsaExerciseProgress.where("user_id=? and
                                                    inst_book_section_exercise_id=?",
                                                              current_user.id,
                                                              inst_book_section_exercise.id).first
          exercise_progress = OdsaExerciseProgress.new(user: current_user,
                                                       inst_book_section_exercise: inst_book_section_exercise)
          exercise_progress.save
        end
      else
        unless exercise_progress = OdsaExerciseProgress.where("user_id=? and
                                                    inst_course_offering_exercise_id=?",
                                                              current_user.id,
                                                              inst_course_offering_exercise.id).first
          exercise_progress = OdsaExerciseProgress.new(user: current_user,
                                                       inst_course_offering_exercise: inst_course_offering_exercise)
          exercise_progress.save
        end
      end

      already_proficient = exercise_progress.proficient?

      correct = params[:score].to_f >= params[:threshold].to_f

      exercise_attempt = OdsaExerciseAttempt.new(
        inst_book_id: params[:inst_book_id],
        user: current_user,
        inst_section: inst_section,
        inst_book_section_exercise: inst_book_section_exercise,
        inst_course_offering_exercise: inst_course_offering_exercise,
        worth_credit: correct,
        correct: correct,
        time_done: Time.now,
        time_taken: (params[:total_time].to_f / 1000).round,
        count_hints: 0,
        count_attempts: params[:uiid],
        hint_used: 0,
        question_name: params[:exercise],
        request_type: "PE",
        ip_address: request.ip,
        pe_score: params[:score],
        pe_steps_fixed: params[:steps_fixed],
      )

      respond_to do |format|
        if exercise_attempt.save
          if hasBook
            exercise_progress = OdsaExerciseProgress.where(
              "user_id=? and inst_book_section_exercise_id=?",
              current_user.id,
              inst_book_section_exercise.id
            ).first
          else
            exercise_progress = OdsaExerciseProgress.find_by(
              inst_course_offering_exercise_id: inst_course_offering_exercise.id,
            )
          end

          format.json {
            render :json => {
                     :exercise_progress => exercise_progress,
                     :threshold => threshold,
                     :was_proficient => already_proficient,
                     :is_proficient => exercise_progress.proficient?,
                   }
          }
        else
          msg = {:status => "fail", :message => "Fail!"}
          format.json { render :json => msg }
        end
      end
    else
      respond_to do |format|
        msg = {:status => "fail", :message => "Fail!"}
        format.json { render :json => msg }
      end
    end
  end

  def get_count
    practiced_ex = OdsaExerciseAttempt.count(:conditions => "request_type <> 'hint'") + OpenDSA::EXERCISES_SOLVED

    respond_to do |format|
      format.json { render :json => {:practiced_ex => practiced_ex} }
    end
  end

  #~ Private instance methods .................................................

  private

  def user_logged_in?
    if current_user.blank?
      error = Error.new(:class_name => 'user_not_logged_in',
                        :message => "User not logged in. \nUser IP: #{request.remote_ip} \nCookie: " + (request.env['HTTP_COOKIE'] || 'No Cookie Set'),
                        trace: Thread.current.backtrace.join("\n"),
                        referer_url: request.env['HTTP_REFERER'],
                        target_url: request.env['HTTP_HOST'] + request.env['REQUEST_URI'],
                        user_agent: request.env['HTTP_USER_AGENT'],
                        params: params.to_json)
      error.save!
      render json: {status: 'fail', message: 'OpenDSA was unable to save your exercise attempt. Please make sure your browser is set to allow third-party cookies. Error id: ' + error.id.to_s}, status: :bad_request
      return false
    end
    return true
  end
end
