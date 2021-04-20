class Lti13::LoginInitiationsController < ApplicationController
  include Lti13::LoginInitiationsHelper
  skip_before_action only: :create
  before_action :set_tool
  before_action :generate_state_jwt

  #
  # OpenID allows for a GET or POST, we account for both here.
  # Both have the same result.
  #

  # GET /lti/login_initiations
  def index;
    redirect_to build_auth_url(@lms_instance, @state_jwt, {login_hint: params[:login_hint], lti_message_hint: params[:lti_message_hint]}, @nonce)
  end

  # POST /lti/login_initiations
  def create
    redirect_to build_auth_url(@lms_instance, @state_jwt, {login_hint: params[:login_hint], lti_message_hint: params[:lti_message_hint]}, @nonce)
  end

  private
    def set_tool
      @lms_instance = LmsInstance.find_by(url: params[:iss], client_id: params[:client_id])
      render json: { error: 'Tool not found' }, status: :not_found unless @lms_instance
    end

    def generate_state_jwt
      @nonce = SecureRandom.hex(10)
      @state_jwt = Lti13Service::StateJwt.new(@lms_instance, { tool_id: @lms_instance.id, state_nonce: @nonce, params: params.as_json }).call
    end
end
