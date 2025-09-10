require 'ostruct'
# Note: (big fix for the 404 client error for LTI 1.3 login intiiations will be 
# to update all @tool to @lms_instance in all LTI 1.3 haml/erb and controller files
# Although the running the LTI 1.3 login intiations works well locally, but the 404s are on staging

class Lti13::LoginInitiationsController < ApplicationController
  include Lti13::LoginInitiationsHelper
  skip_before_action only: :create
  before_action :set_tool
  before_action :generate_state_jwt

  # OpenID allows for a GET or POST

  # GET /lti13/login_initiations
  def index
    Rails.logger.debug('[LTI13::LoginInitiations#index] rendering index')
    # The index view expects an object called @tool. 
    # we already have an @lms_instance (populated from the session)
    # and @tool is an abstraction that has not been set yet, create the view-friendly wrapper.
    unless defined?(@tool) && @tool
      @tool = present_as_tool(@lms_instance) if @lms_instance
      Rails.logger.info "[LoginInitiations#index] built @tool: #{@tool.inspect}"
    end
  end

  # POST /lti13/login_initiations
  def create
    auth_url = build_auth_url(@lms_instance, @state_jwt, {
      login_hint: params[:login_hint], 
      lti_message_hint: params[:lti_message_hint]
    }, @nonce)  
    Rails.logger.info "LoginInitiationsController#create: auth_url: #{auth_url}"
    redirect_to auth_url
  end

  #~ Private methods ..........................................................

  private
  # -------------------------------------------------------------
  def set_tool
    issuer = params[:iss]
    client_id = params[:client_id]
    Rails.logger.info "Received Issuer: #{issuer}"
    Rails.logger.info "Received Client ID: #{client_id}"
    @lms_instance = LmsInstance.find_by(issuer: issuer, client_id: client_id)

    unless @lms_instance
      Rails.logger.warn 'set_tool: LMS Instance NOT found'
      render json: { error: 'LMS Instance not found or configuration mismatch' }, status: :not_found
      return
    end
    # Build @tool alias for views that still use @tool
    # Remove/comment this line out after big fix
    @tool = present_as_tool(@lms_instance)
    Rails.logger.debug "[set_tool] @tool proxy: #{@tool.inspect}"

    # Store LTI1.3 params in session so we can use this for subsequent requests to index 
    # so the next GET for /lti13/login_initiations index can easily access the @lms_instance
    session[:lms_instance_id] = @lms_instance.id
    session[:issuer]          = @lms_instance.issuer
    session[:client_id]       = @lms_instance.client_id
  end

  # Helper to makes this struct available to the view layer 
  # Remove/comment this method out after big fix
  def present_as_tool(lms)
    OpenStruct.new(
      id:                       lms.id,
      name:                     (lms.respond_to?(:name) && lms.name.present?) ? lms.name : (lms.url || lms.issuer),
      client_id:                lms.client_id,
      issuer:                   lms.issuer,
      platform_oidc_auth_url:   lms.platform_oidc_auth_url,
      oauth2_url:               lms.oauth2_url
    )
  end

  def generate_state_jwt
    @nonce = SecureRandom.hex(10)
    @state_jwt = Lti13Service::StateJwt.new(@lms_instance, { tool_id: @lms_instance.id, state_nonce: @nonce, params: params.as_json }).call
  end
end