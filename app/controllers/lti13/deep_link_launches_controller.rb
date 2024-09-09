class Lti13::DeepLinkLaunchesController < ApplicationController
  before_action :set_tool
  skip_before_action only: :create

  # POST lti/tools/#/deep_link_launches
  # Handles the creation of a deep link launch
  def create
    if params[:id_token]&.present?
      @decoded_header = Jwt::Header.new(params[:id_token]).call
      kid = @decoded_header['kid']

      @decoded_jwt = Lti13Service::DecodePlatformJwt.new(@tool, params[:id_token], kid).call
      @launch = @tool.launches.build(jwt: params[:id_token], decoded_jwt: @decoded_jwt ? @decoded_jwt.first : nil, state: params[:state])
    end

    @launch ||= Launch.new
    respond_to do |format|
      if @launch.save
        format.html { redirect_to [:lti13, @tool, @launch], notice: 'Successful Launch.' }
        format.json { render :show, status: :created, location: @launch }
      else
        format.html { render json: 'Invalid Launch', status: :unprocessable_entity }
        format.json { render json: @launch.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET lti/tools/#/deep_link_launch/*launch_id*
  # allows user to select content
  def show
    @launch = Launch.find(params[:id])
  end

  # GET lti/tools/#/deep_link_launch/*launch_id*/launch
  # takes selected content and launches back to platform with JWT
  def launch
    @launch = Launch.find(params[:deep_link_launch_id])
    @form_url = @launch.decoded_jwt[Rails.configuration.lti_claims_and_scopes['deep_linking_claim']]['deep_link_return_url']
    @deep_link_jwt = Lti13Service::DeepLinkJwt.new(@launch, lti_tool_launches_url(@tool), params[:content_items])
  end

  # GET lti13/deep_linking/content_selection
  def content_selection
    @launch_url = request.protocol + request.host_with_port + "/lti13/launches"
    module_info = InstModule.get_current_versions_dict()
    @json = module_info.to_json

    Rails.logger.info "Launch URL: #{@launch_url}"
    Rails.logger.debug "Module Info JSON: #{@json.inspect}"
    render 'resource', layout: 'lti_resource'
  end

  # POST lti13/deep_linking/content_selected
  def content_selected
    @launch = Launch.find(params[:launch_id]) 
    @form_url = @launch.decoded_jwt[Rails.configuration.lti_claims_and_scopes['deep_linking_claim']]['deep_link_return_url']
    selected_content = params[:selected_content] 
    Rails.logger.info "Selected Content: #{selected_content}"

    deep_link_jwt_service = Lti13Service::DeepLinkJwt.new(@launch, selected_content)
    deep_link_jwt = deep_link_jwt_service.call
    Rails.logger.info "Deep Link JWT: #{deep_link_jwt}"

    # Return the selected content to LMS
    redirect_to "#{@form_url}?JWT=#{deep_link_jwt}"
  end

  #~ Private methods ..........................................................

  private
  # -------------------------------------------------------------

  def set_tool
    @tool = Tool.find_by_id(params[:tool_id])
    render json: { error: 'Tool not found' }, status: :not_found unless @tool
  end
end