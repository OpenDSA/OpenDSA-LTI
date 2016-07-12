class OdsaExerciseProgressesController < ApplicationController
  # load_and_authorize_resource

  #~ Action methods ...........................................................

  def update
    inst_exercise = InstExercise.find_by(short_name: params[:exercise_name])
    inst_book_section_exercise = InstBookSectionExercise.where(
                                  "inst_book_id=? and inst_section_id=? and inst_exercise_id=?",
                                  params[:inst_book_id], params[:inst_section_id], inst_exercise.id).first

    unless exercise_progress = OdsaExerciseProgress.where("user_id=? and inst_book_section_exercise_id=?",
                                                 current_user.id,
                                                 inst_book_section_exercise.id).first

      exercise_progress = OdsaExerciseProgress.new(user: current_user,
                                                    inst_book_section_exercise: inst_book_section_exercise)
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
