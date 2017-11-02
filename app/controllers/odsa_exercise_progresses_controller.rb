class OdsaExerciseProgressesController < ApplicationController
  # load_and_authorize_resource

  #~ Action methods ...........................................................
  def update
    inst_exercise = InstExercise.find_by(short_name: params[:exercise_name])
    hasBook = params.key?([:inst_book_id])
    if hasBook
      inst_book_section_exercise = InstBookSectionExercise.where(
                                    "inst_book_id=? and inst_section_id=? and inst_exercise_id=?",
                                    params[:inst_book_id], params[:inst_section_id], inst_exercise.id).first

      unless exercise_progress = OdsaExerciseProgress.where("user_id=? and inst_book_section_exercise_id=?",
                                              current_user.id,
                                              inst_book_section_exercise.id).first

        exercise_progress = OdsaExerciseProgress.new(user: current_user,
                                                inst_book_section_exercise: inst_book_section_exercise)
      end
    else
      unless exercise_progress = OdsaExerciseProgress.where("user_id=? and inst_course_offering_exercise_id=?",
                                                 current_user.id,
                                                 params[:inst_course_offering_exercise_id]).first

            exercise_progress = OdsaExerciseProgress.new(user: current_user,
                                        inst_course_offering_exercise_id: params[:inst_course_offering_exercise_id])
      end
    end
    exercise_progress['current_exercise'] = params['current_exercise']

    respond_to do |format|
      if exercise_progress.save
        msg = { :status => "success", :message => "Success!" }
      else
        msg = { :status => "fail", :message => "Fail!" }
      end
      format.json  { render :json => msg }
    end
  end

  def show_exercise
    inst_exercise = InstExercise.find_by(short_name: params[:exercise_name])
    hasBook = params.key?(:inst_book_id)
    if hasBook
      inst_book_section_exercise = InstBookSectionExercise.where(
                                    "inst_book_id=? and inst_section_id=? and inst_exercise_id=?",
                                    params[:inst_book_id], params[:inst_section_id], inst_exercise.id).first
      exercise_progress = OdsaExerciseProgress.where(
                                    "inst_book_section_exercise_id=? and user_id=?",
                                    inst_book_section_exercise.id, current_user.id).first
      threshold = inst_book_section_exercise.threshold
    else
      inst_course_offering_exercise = InstCourseOfferingExercise.find_by(id: params[:inst_course_offering_exercise_id])
      exercise_progress = OdsaExerciseProgress.find_by(
        inst_course_offering_exercise_id: inst_course_offering_exercise.id,
        user_id: current_user.id)
      threshold = inst_course_offering_exercise.threshold
    end
    # inst_book_section_exercise = InstBookSectionExercise.find_by(id: exercise_progress.inst_book_section_exercise_id)
    respond_to do |format|
      format.json  { render :json => {
                                      :exercise_progress => exercise_progress,
                                      :threshold => threshold}}
    end
  end

  # Retrieves proficiency status of all exercises
  def show_section
    book_progress = OdsaBookProgress.where("user_id=? and inst_book_id=?",
                                           current_user.id, params[:inst_book_id]).first
    proficient_exercises = []
    if book_progress
      proficient_exercises = book_progress.get_proficient_exercises
    end

    respond_to do |format|
      format.json  { render :json => {:proficient_exercises => proficient_exercises}}
    end
  end

  def get_count
    practiced_ex = OdsaExerciseProgress.count(:conditions => "proficient_date IS NOT NULL") + CodeWorkout::EXERCISES_SOLVED

    respond_to do |format|
      format.json  { render :json => {:practiced_ex => practiced_ex}}
    end
  end
  #~ Private instance methods .................................................
end
