class Lti13::LoginInitiationsController < ApplicationController
  include Lti13::LoginInitiationsHelper
  #Todo :move debug statements to tests
  skip_before_action only: :create
  before_action :set_tool
  before_action :generate_state_jwt

  def create
    puts "LoginInitiationsController#create: Initiating login process"
    auth_url = build_auth_url(@lms_instance, @state_jwt, {
      login_hint: params[:login_hint], 
      lti_message_hint: params[:lti_message_hint]
    }, @nonce)
  
    puts "LoginInitiationsController#create: Redirecting to #{auth_url}"
    redirect_to auth_url
  end

  private

  def set_tool
    issuer = params[:iss]
    client_id = params[:client_id]
    puts "Received Issuer: #{issuer}"
    puts "Received Client ID: #{client_id}"
    # Find the LMS instance from the database
    @lms_instance = LmsInstance.find_by(issuer: issuer, client_id: client_id)

    unless @lms_instance
      render json: { error: 'LMS Instance not found or configuration mismatch' }, status: :not_found
      return
    end
  end

  def generate_state_jwt
    @nonce = SecureRandom.hex(10)
    @state_jwt = Lti13Service::StateJwt.new(@lms_instance, { tool_id: @lms_instance.id, state_nonce: @nonce, params: params.as_json }).call
  end
end