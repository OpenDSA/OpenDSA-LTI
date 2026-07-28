class Lti13::DynamicRegistrationsController < ApplicationController
  layout 'lti13'
  after_action :allow_iframe, only: [:show, :create]

  # GET /lti13/dynamic_registration?openid_configuration=...&registration_token=...
  # Opened by the platform (Canvas) in an iframe or new tab when the
  # platform admin initiates dynamic registration. Fetches the platform's
  # openid-configuration and renders a confirmation page.
  def show
    @openid_configuration = params[:openid_configuration]
    @registration_token = params[:registration_token]

    if @openid_configuration.blank?
      @error = 'Missing openid_configuration parameter. This URL is meant to be opened by the LMS during dynamic registration.'
      return
    end

    @platform_config = fetch_platform_config(@openid_configuration)
    if @platform_config.nil?
      @error = "Could not fetch platform configuration from #{@openid_configuration}."
      return
    end

    @issuer = @platform_config['issuer']
    if @issuer.blank?
      @error = "Platform openid-configuration at #{@openid_configuration} did not include an issuer."
      return
    end

    unless issuer_matches_url?(@issuer, @openid_configuration)
      @error = "Issuer (#{@issuer}) does not match openid_configuration URL (#{@openid_configuration}). Registration aborted to prevent impersonation."
      return
    end

    if @platform_config['registration_endpoint'].blank?
      @error = "Platform openid-configuration did not include a registration_endpoint. This platform does not support LTI 1.3 Dynamic Registration."
      return
    end

    @existing_instance = LmsInstance.find_by(url: @issuer)
  end

  # POST /lti13/dynamic_registration
  # Performs the actual registration after the user confirms on #show.
  def create
    # The URLs we register with the platform (JWKS, redirect, login)
    # must be HTTPS — Canvas (and the LTI 1.3 spec) reject HTTP URLs.
    # Rails sits behind a TLS-terminating proxy so request.protocol may
    # report 'http://' even when the user-facing URL is HTTPS; force HTTPS.
    base_url = "https://#{request.host_with_port}"
    service = Lti13Service::DynamicRegistration.new(
      openid_configuration: params[:openid_configuration],
      registration_token: params[:registration_token],
      base_url: base_url
    )
    result = service.call

    if result[:success]
      @lms_instance = result[:lms_instance]
      render :success, layout: false
    else
      @error = result[:error]
      @openid_configuration = params[:openid_configuration]
      @registration_token = params[:registration_token]
      render :show, status: :unprocessable_entity
    end
  end

  private

  def fetch_platform_config(url)
    response = Faraday.get(url) do |req|
      req.headers['Accept'] = 'application/json'
    end
    return nil unless response.status == 200
    JSON.parse(response.body)
  rescue => e
    Rails.logger.error "DynamicRegistrations#fetch_platform_config: #{e.message}"
    nil
  end

  def issuer_matches_url?(issuer, url)
    return false if issuer.blank? || url.blank?
    url == issuer || url.start_with?(issuer + '/')
  rescue
    false
  end

  # Dynamic registration is opened by the platform in an iframe, but at
  # #show time we don't yet know which platform it is (the LmsInstance
  # doesn't exist yet — that's the whole point). Allow any HTTPS origin
  # to embed the registration page. The registration_token provides the
  # actual security (short-lived, single-use, issued by the platform).
  def allow_iframe
    response.headers.except! 'X-Frame-Options'
    response.headers['Content-Security-Policy'] = "frame-ancestors 'self' https:"
  end
end
