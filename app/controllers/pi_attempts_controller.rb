class PiAttemptsController < ApplicationController

  # POST /pi_attempts
  def create
    PiAttempt.create(user_id: current_user.id, frame_name: params[:frame_name], question: params[:question], correct: params[:correct])
    result = {"result" => "PIAttempt was successfully created."}
    respond_to do |format|
      format.json {render json: result}
    end
  end

  # POST /pi_attempts/get_attempts
  def get_attempts
    attempts = PiAttempt.where(user_id: current_user.id, frame_name: params[:frame_name], question: params[:question]).count
    result = {"result" => attempts}
    respond_to do |format|
      format.json {render json: result}
    end
  end

  # POST /pi_attempts/get_checkpoint
  def get_checkpoint
    checkpoint = PiAttempt.where(user_id: current_user.id, frame_name: params[:frame_name]).maximum("question")
    result = {"result" => checkpoint}
    respond_to do |format|
      format.json {render json: result}
    end
  end

  # POST /pi_attempts/get_progress
  def get_progress
    progress = PiAttempt.where(user_id: current_user.id, frame_name: params[:frame_name], correct: 1).maximum("question")
    result = {"result" => progress}
    respond_to do |format|
      format.json {render json: result}
    end
  end

end