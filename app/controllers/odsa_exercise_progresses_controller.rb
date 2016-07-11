class OdsaExerciseProgressesController < ApplicationController
  # load_and_authorize_resource

  #~ Action methods ...........................................................

  def create
    inst_book = InstBook.find_by(id: params[:inst_book_id])
    inst_section = InstSection.find_by(id: params[:inst_section_id])
    inst_exercise = InstExercise.find_by(short_name: params[:sha1])
    inst_book_section_exercise = InstBookSectionExercise.where(
                                  "inst_book_id=? and inst_section_id=? and inst_exercise_id=?",
                                  params[:inst_book_id], params[:inst_section_id], inst_exercise.id).first

    unless exercise_progress = OdsaExerciseProgress.where("user_id=? and inst_book_section_exercise_id=?",
                                                 current_user.id,
                                                 inst_book_section_exercise.id).first

      exercise_progress = OdsaExerciseProgress.new(user: current_user,
                                                    inst_book_section_exercise: inst_book_section_exercise)
      exercise_progress.save
    end

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
      worth_credit = worth_credit and (exercise_progress['hinted_exercise'] != question_name)
    end

    exercise_attempt = OdsaExerciseAttempt.new(
                                                inst_book: inst_book,
                                                user: current_user,
                                                inst_section: inst_section,
                                                inst_book_section_exercise: inst_book_section_exercise,
                                                worth_credit: worth_credit,
                                                correct: params[:complete],
                                                time_done: Time.now,
                                                time_taken: params[:time_taken],
                                                count_hints: params[:count_hints],
                                                count_attempts: params[:attempt_number],
                                                hint_used: params[:count_hints].to_i > 0,
                                                question_name: question_name,
                                                request_type: request_type ,
                                                points_earned: 1, # TODO: relace with the correct value
                                                earned_proficiency: true, # TODO: relace with the correct value
                                                ip_address: request.ip)

    respond_to do |format|
      if exercise_attempt.save

        exercise_progress = OdsaExerciseProgress.where(
                                                  "user_id=? and inst_book_section_exercise_id=?",
                                                  current_user.id,
                                                  inst_book_section_exercise.id).first


        format.json  { render :json => {
                                        :exercise_progress => exercise_progress,
                                        :threshold => inst_book_section_exercise.threshold}}
      else
        msg = { :status => "fail", :message => "Fail!" }
        format.json  { render :json => msg }
      end
    end
  end

  def show
    inst_exercise = InstExercise.find_by(short_name: params[:exercise_name])
    inst_book_section_exercise = InstBookSectionExercise.where(
                                  "inst_book_id=? and inst_section_id=? and inst_exercise_id=?",
                                  params[:inst_book_id], params[:inst_section_id], inst_exercise.id).first
    exercise_progress = OdsaExerciseProgress.where(
                                  "inst_book_section_exercise_id=? and user_id=?",
                                  inst_book_section_exercise.id, current_user.id).first
    # inst_book_section_exercise = InstBookSectionExercise.find_by(id: exercise_progress.inst_book_section_exercise_id)
    respond_to do |format|
      format.json  { render :json => {
                                      :exercise_progress => exercise_progress,
                                      :threshold => inst_book_section_exercise.threshold}}
    end
  end

  #~ Private instance methods .................................................
end
