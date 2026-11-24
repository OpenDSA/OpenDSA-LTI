class Lti13::DeepLinkLaunchesController < ApplicationController
  before_action :set_lms_instance, only: [:create, :show, :content_selection]
  before_action :set_launch_for_content_selected, only: [:content_selected]
  after_action :allow_iframe, only: [:show, :content_selection, :content_selected]

  # POST /lti13/deep_link_launches
  def create
    if params[:id_token]&.present?
      @decoded_header = Jwt::Header.new(params[:id_token]).call
      kid = @decoded_header['kid']

      @decoded_jwt = Lti13Service::DecodePlatformJwt.new(@lms_instance, params[:id_token], kid).call
      normalized_jwt = @decoded_jwt.is_a?(Array) ? @decoded_jwt.first : @decoded_jwt
      @launch = @lms_instance.lti_launches.build(id_token: params[:id_token], decoded_jwt: normalized_jwt, state: params[:state], expires_at: Time.now + 1.hour)
    end

    @launch ||= LtiLaunch.new
    respond_to do |format|
      if @launch.save
        format.html { redirect_to [:lti13, @lms_instance, @launch], notice: 'Successful Launch.' }
        format.json { render :show, status: :created, location: @launch }
      else
        format.html { render json: 'Invalid Launch', status: :unprocessable_entity }
        format.json { render json: @launch.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /lti13/deep_link_launches/:id
  def show
    @launch = LtiLaunch.find(params[:id])
  end

  # GET /lti13/deep_linking/content_selection
  def content_selection
    @launch_url = request.protocol + request.host_with_port + "/lti13/launches"
    module_info = InstModule.get_current_versions_dict()
    @json = module_info.to_json

    Rails.logger.info "Launch URL: #{@launch_url}"
    Rails.logger.debug "Module Info JSON: #{@json.inspect}"
    render 'resource', layout: 'lti_resource'
  end

  # POST /lti13/deep_linking/content_selected
  # Accepts a JSON body from lti_resource.js with:
  #   launch_id, lms_instance_id, selected: { moduleInfo|exerciseInfo, ...settings, isGradable }
  # Builds a signed LtiDeepLinkingResponse JWT and returns a redirect URL
  # of the form "<deep_link_return_url>?JWT=<jwt>" for the browser to redirect to.
  def content_selected
    selected_content = params[:selected]
    Rails.logger.info "Selected Content: #{selected_content.inspect}"

    selected_hash = selected_content.respond_to?(:to_unsafe_h) ? selected_content.to_unsafe_h : selected_content

    deep_link_jwt_service = Lti13Service::DeepLinkJwt.new(@launch, @lms_instance, lti13_launches_url, selected_hash)
    deep_link_jwt = deep_link_jwt_service.call
    Rails.logger.info "Deep Link JWT: #{deep_link_jwt}"

    return_url = deep_link_return_url(@launch)
    if return_url.blank?
      render json: { error: 'Deep Linking return URL not found in launch JWT' }, status: :unprocessable_entity
      return
    end

    render json: { jwt: deep_link_jwt, return_url: return_url }
  end

  #~ Private methods ..........................................................

  private

  def set_lms_instance
    lms_instance_id = params[:lms_instance_id] || session[:lms_instance_id]
    @lms_instance = LmsInstance.find_by(id: lms_instance_id)
    render json: { error: 'LMS Instance not found' }, status: :not_found unless @lms_instance
  end

  def set_launch_for_content_selected
    @launch = LtiLaunch.find_by(id: params[:launch_id])
    if @launch.nil?
      render json: { error: 'LtiLaunch not found' }, status: :not_found
      return
    end
    @lms_instance = @launch.lms_instance
    if @lms_instance.nil?
      render json: { error: 'LMS Instance not found for launch' }, status: :not_found
    end
  end

  def deep_link_return_url(launch)
    jwt_payload = launch.decoded_jwt.is_a?(Array) ? launch.decoded_jwt.first : launch.decoded_jwt
    jwt_payload&.dig(Rails.configuration.lti_claims_and_scopes['deep_linking_claim'], 'deep_link_return_url')
  end

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
    Rails.logger.debug "Response headers after removing X-Frame-Options from deep_link_controller: #{response.headers.inspect}"
    response.headers['Content-Security-Policy'] = "frame-ancestors #{frame_ancestors_directive}"
  end

  def frame_ancestors_directive
    ancestors = "'self'"
    url = @lms_instance&.url
    return ancestors if url.blank?
    uri = URI.parse(url)
    origin = "#{uri.scheme}://#{uri.host}"
    origin << ":#{uri.port}" if uri.port && uri.port != uri.default_port
    "#{ancestors} #{origin}"
  rescue URI::InvalidURIError => e
    Rails.logger.warn "allow_iframe: invalid LMS instance URL #{url.inspect}: #{e.message}"
    ancestors
  end

end
