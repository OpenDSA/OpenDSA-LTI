class PiAttemptsController < ApplicationController

  # POST /pi_attempts
  def create
    PiAttempt.create(user_id: current_user.id, frame_name: params[:frame_name], question: params[:question], correct: params[:correct])
  end

  # GET /pi_attempts/get_attempts
  def get_attempts
    attempts = PiAttempt.where(user_id: current_user.id, frame_name: params[:frame_name], question: params[:question]).count
    respond_do |format|
      format.html
      format.json {render json: attempts}
    end
  end

  # GET /pi_attempts/get_checkpoint
  def get_checkpoint
    checkpoint = PiAttempt.where(user_id: current_user.id, frame_name: params[:frame_name]).maximum("question")
    respond_do |format|
      format.html
      format.json {render json: checkpoint}
    end
  end

  # GET /pi_attempts/get_progress
  def get_progress
    progress = PiAttempt.where(user_id: current_user.id, frame_name: params[:frame_name], correct: 1).maximum("question")
    respond_do |format|
      format.html
      format.json {render json: progress}
    end
  end

end