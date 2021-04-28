class Lti13::LaunchesController < ApplicationController
  layout 'lti13', only: [:create]
  before_action :set_tool
  # before_action :set_launch, only: %i[show edit update destroy]
  skip_before_action only: :create
  after_action :allow_iframe, only: [:create]

  # GET /launches
  # GET /launches.json
  def index
    @launches = @lms_instance.launches
  end

  # GET /launches/1
  # GET /launches/1.json
  def show
    Rails.application.executor.wrap { @access_token = @lms_instance.oauth2_url.present? ? Lti13Service::GetAgsAccessToken.new(@lms_instance).call : nil }
    # caliper event background job
    # ToolUseEventWorker.perform_async(@lms_instance.id, @launch.id, root_url, request.uuid)
  end

  # GET /launches/new
  def new
    @launch = Launch.new
  end

  # GET /launches/1/edit
  def edit; end

  # POST /launches
  # POST /launches.json
  def create
    # TODO: to be changed to including the following
    # - id_token validation
    # -- verfiy it is coming from the issuer
    # -- verify the request was not expired as defined in the state token
    # -- https://purl.imsglobal.org/spec/lti/claim/target_link_uri claim should have the same value as sent in the login initiation
    # -- nonce should be the same as sent in the login initiation
    # - get the access token with all possible claims and cache it
    # - check the cookie value is equal as was sent in the login initiaiton redirect
    # - send the content back as html
    if params[:id_token]&.present?
      @decoded_header = Jwt::Header.new(params[:id_token]).call
      kid = @decoded_header['kid']

      @decoded_jwt = Lti13Service::DecodePlatformJwt.new(@lms_instance, params[:id_token], kid).call
      @decoded_jwt = @decoded_jwt.first

      @id_token = params[:id_token]
      Rails.application.executor.wrap { @access_token = @lms_instance.oauth2_url.present? ? Lti13Service::GetAgsAccessToken.new(@lms_instance).call : nil }
    end

    return
  end

  # PATCH/PUT /launches/1
  # PATCH/PUT /launches/1.json
  def update
    respond_to do |format|
      if @launch.update(launch_params)
        format.html { redirect_to [:lti, @lms_instance, @launch], notice: 'Tool launch was successfully updated.' }
        format.json { render :show, status: :ok, location: @launch }
      else
        format.html { render :edit }
        format.json { render json: @launch.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /launches/1
  # DELETE /launches/1.json
  def destroy
    @launch.destroy
    respond_to do |format|
      format.html { redirect_to lti_tool_launches_url(@lms_instance), notice: 'Tool launch was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    def set_tool
      @lms_instance = LmsInstance.find_by(id: 3)
      render json: { error: 'Tool not found' }, status: :not_found unless @lms_instance
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_launch
      @launch = Launch.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def launch_params
      params.require(:launch).permit(:jwt, :decoded_jwt, :tool_id, :state)
    end

    def allow_iframe
      response.headers.except! 'X-Frame-Options'
    end

end
