class StudentExerciseProgressesController < ApplicationController
  # POST /new_progress
  def create
    @progress = StudentExerciseProgress.new(user_id: current_user.id, exercise_id: params[:exercise_id], progress: params[:progress], grade: params[:grade])
    @progress.save
    result = {"result" => "solution stored successfully."}

    respond_to do |format|
        format.json {render json: result}
    end
  end

  # POST /get_progress
  def fetch
      @progress = StudentExerciseProgress.where(user_id: current_user.id, exercise_id: params[:exercise_id]).order("created_at").last
      result = {"progress" => @progress}
      
      respond_to do |format|
          format.json {render json: result}
      end
  end
end
