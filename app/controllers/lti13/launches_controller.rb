class Lti13::LaunchesController < ApplicationController
  include Lti13::LaunchesHelper
  layout 'lti13', only: [:create]
  skip_before_action only: :create
  # before_action :set_tool
  # before_action :set_launch, only: %i[show edit update destroy]
  after_action :allow_iframe, only: [:create]

  # GET /launches
  def index
    puts "from index"
    @launches = @lms_instance.launches
  end

  # GET /launches/1
  def show
    puts "from show"
    Rails.application.executor.wrap { @access_token = @lms_instance.oauth2_url.present? ? Lti13Service::GetAgsAccessToken.new(@lms_instance).call : nil }
    # caliper event background job
    # ToolUseEventWorker.perform_async(@lms_instance.id, @launch.id, root_url, request.uuid)
  end

  # GET /launches/new
  def new
    puts "new"
    @launch = Launch.new
  end

  # GET /launches/1/edit
  def edit; end

  # POST /launches
  def create
    # (ID token validation and other launch processes) with debug statements to track flow
    puts "LaunchesController#create: Starting LTI 1.3 launch process"
    puts "Launch request params: #{params.inspect}"
  
    if params[:id_token]&.present?
      puts "LaunchesController#create: Found ID token: #{params[:id_token]}"
  
      if params[:state]&.present?
        # Verify the state coming from the platform
        @decoded_payload = Jwt::Payload.new(params[:state]).call
  
        if @decoded_payload.nil?
          puts "LaunchesController#create: Decoded payload is nil"
          # might nedd to handle the error appropriately, perhaps by rendering an error message or redirecting
          return
        end
        
        tool_id = @decoded_payload['tool_id']
        @lms_instance = LmsInstance.find_by(id: tool_id.to_i)
        
        puts "LaunchesController#create: Decoded state: #{@decoded_payload}"
      else
        puts "LaunchesController#create: State parameter missing"
      end
  
      @decoded_header = Jwt::Header.new(params[:id_token]).call
      kid = @decoded_header['kid']
  
      # Handle potential errors when fetching platform keys
      puts "Keyset URL from create: #{@lms_instance&.keyset_url}"
      # Fetch platform keys
      keys_response = Lti13Service::Keys.new(@lms_instance.keyset_url).call
      if keys_response.nil?
        puts "LaunchesController#create: Error fetching keys from keyset URL"
        # ToDo :Handle error response (e.g., render an error page or return a specific response)
      else
        puts "Decode platform jwt:"
        @decoded_jwt = Lti13Service::DecodePlatformJwt.new(@lms_instance, params[:id_token], kid).call
  
        puts "LaunchesController#create: Decoded JWT: #{@decoded_jwt}"
  
        @id_token = params[:id_token]
        Rails.application.executor.wrap { @access_token = @lms_instance.oauth2_url.present? ? Lti13Service::GetAgsAccessToken.new(@lms_instance).call : nil }
  
        # Testing AGS score service {Call send_score action from Lti13::ServicesController with necessary parameters}
        Lti13::ServicesController.new.send_score(launch_id: @lms_instance.id, access_token: @access_token, platform_jwt: params[:id_token], kid: kid)       
      end
    else
      puts "LaunchesController#create: ID token missing"
    end
  end
  
  # PATCH/PUT /launches/1
  def update
    # (Update logic)
  end

  # DELETE /launches/1
  def destroy
    # (Destroy logic)
  end

  private

  def set_launch
    @launch = Launch.find(params[:id])
  end

  def launch_params
    params.require(:launch).permit(:jwt, :decoded_jwt, :tool_id, :state)
  end

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end
end


  