class PiAttemptsController < ApplicationController

  # POST /pi_attempts
  def create
    PiAttempt.create(user_id: current_user.id, frame_name: params[:frame_name], question: params[:question], correct: params[:correct])
  end

  # GET /pi_attempts/get_attempts
  def get_attempts
    PiAttempt.where(user_id: current_user.id, frame_name: params[:frame_name], question: params[:question]).count
  end

  # GET /pi_attempts/get_checkpoint
  def get_checkpoint
    PiAttempt.where(user_id: current_user.id, frame_name: params[:frame_name]).maximum("question")
  end

  # GET /pi_attempts/get_progress
  def get_progress
    PiAttempt.where(user_id: current_user.id, frame_name: params[:frame_name], correct: 1).maximum("question")
  end

end