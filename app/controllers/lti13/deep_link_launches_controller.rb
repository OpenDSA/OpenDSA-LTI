class Lti13::DeepLinkLaunchesController < ApplicationController
    before_action :set_tool
    skip_before_action only: :create
  
    # POST lti/tools/#/deep_link_launches
    # Not much different than LTI launch endpoint inside a simple reference implementation but you
    # should have a diff endpoint for deeplinks than your LTI resource link request for single responsiblity
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
          format.html { redirect_to [:lti, @tool, @launch], notice: 'Successful Launch.' }
          format.json { render :show, status: :created, location: @launch }
        else
          format.html { render json: 'Invalid Launch', status: :unprocessable_entity }
          format.json { render json: @launch.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # GET lti/tools/#/deep_link_launch/*launch_id*
    # page that allows user to select content
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
  
    private
      def set_tool
        @tool = Tool.find_by_id(params[:tool_id])
        render json: { error: 'Tool not found' }, status: :not_found unless @tool
      end
  end