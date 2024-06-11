class Lti13::LaunchesController < ApplicationController
  include Lti13::LaunchesHelper
  layout 'lti', only: [:create]
  after_action :allow_iframe, only: [:create, :handle_resource_link_request]

  # GET /launches
  def index
    puts "from index"
    @launches = @lms_instance.launches
  end

  # GET /launches/1
  def show
    puts "from show"
    Rails.application.executor.wrap { @access_token = @lms_instance.oauth2_url.present? ? Lti13Service::GetAgsAccessToken.new(@lms_instance).call : nil }
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
    Rails.logger.info " Starting LTI 1.3 launch process: Launch request params: #{params.inspect}"
    if params[:id_token]&.present?
      puts "LaunchesController#create: Found ID token: #{params[:id_token]}"

      if params[:state]&.present?
        @decoded_payload = Jwt::Payload.new(params[:state]).call
        if @decoded_payload.nil?
          Rails.logger.info "LaunchesController#create: Decoded payload is nil"
          return
        end

        tool_id = @decoded_payload['tool_id']
        @lms_instance = LmsInstance.find_by(id: tool_id.to_i)
        Rails.logger.info "LaunchesController#create: Decoded state: #{@decoded_payload}"
      else
        Rails.logger.info "LaunchesController#create: State parameter missing"
      end

      @decoded_header = Jwt::Header.new(params[:id_token]).call
      kid = @decoded_header['kid']
      keys_response = Lti13Service::Keys.new(@lms_instance.keyset_url).call
      if keys_response.nil?
        Rails.logger.info "LaunchesController#create: Error fetching keys from keyset URL"
      else
        @decoded_jwt = Lti13Service::DecodePlatformJwt.new(@lms_instance, params[:id_token], kid).call
        Rails.logger.info "LaunchesController#create: Decoded JWT: #{@decoded_jwt}"

        @id_token = params[:id_token]
        @access_token = Lti13Service::GetAgsAccessToken.new(@lms_instance).call
        Rails.logger.info "access token launches controller#create: access token: #{@access_token}"

        if @access_token.nil?
          Rails.logger.info "Failed to retrieve access token in LaunchesController#create"
          return
        end
        # Call set_user after decoding JWT
        set_user

        message_type_claim = @decoded_jwt.find { |claim| claim.has_key?('https://purl.imsglobal.org/spec/lti/claim/message_type') }
        message_type = message_type_claim['https://purl.imsglobal.org/spec/lti/claim/message_type']

        case message_type
        when 'LtiResourceLinkRequest'
          handle_resource_link_request
        when 'LtiDeepLinkingRequest'
          handle_deep_linking_request
        else
          render 'error' and return
        end
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

  def handle_resource_link_request
    # show the LTI request parameters
    puts "handle_resource_link_request: params - #{params.inspect}"
  
    # Extract necessary parameters from the decoded JWT
    decoded_jwt = @decoded_jwt.first
  
    # Debug: decoded JWT
    puts "Decoded JWT: #{decoded_jwt}"
  
    # Extracting the target_link_uri from the decoded JWT
    target_link_uri = decoded_jwt["https://purl.imsglobal.org/spec/lti/claim/target_link_uri"]
    uri = URI.parse(target_link_uri)
    query_params = CGI.parse(uri.query)
  
    file_name = query_params["custom_module_file_name"]&.first
    book_path = query_params["custom_book_path"]&.first
  
    # Debug: print extracted parameters
    puts "Extracted file name from target_link_uri: #{file_name}"
    puts "Extracted book path from target_link_uri: #{book_path}"
  
    @course_offering = @lms_instance.course_offerings.first 
  
    # Debug: print course offerings and selected course offering
    puts "Course offerings from the platform/lms: #{@lms_instance.course_offerings.pluck(:id, :label)}"
    puts "Selected course offering: #{@course_offering.inspect}"
  
    unless @course_offering
      render plain: "Course offering not found", status: :not_found
      return
    end
  
    if file_name && book_path
      # Debug: show the file path being read
      file_path = File.join('public/OpenDSA/Books', book_path, '/lti_html/', "#{file_name}.html")
      puts "Reading file at: #{file_path}"
  
      @section_html = File.read(file_path)
      render 'launch', layout: 'lti13'
    else
      render plain: "File name or book path not found (3)!", status: :unprocessable_entity
    end
  end

  def handle_deep_linking_request
    redirect_to lti13_deep_linking_content_selection_path(jwt: @decoded_jwt)
  end

  def set_user
    decoded_jwt = @decoded_jwt.first
    lti11_legacy_user_id = decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/lti11_legacy_user_id']
    sub = decoded_jwt['sub']
    email = decoded_jwt.dig('https://purl.imsglobal.org/spec/lti/claim', 'email')
  
    # find the user by email if available
    if email.present?
      @user = User.find_by(email: email)
      puts "User found by email: #{@user.inspect}" if @user
    end
  
    # If user is not found by email, proceed to check via NRPS
    if @user.blank?
      puts "User not found by email, checking NRPS service"
      lms_instance = @lms_instance
  
      access_token_response = Lti13Service::GetAgsAccessToken.new(lms_instance).call
      access_token = access_token_response['access_token'] if access_token_response
  
      if access_token.blank?
        puts "Failed to retrieve access token"
        @message = 'OpenDSA: Failed to retrieve access token'
        return false
      end
  
      response = Lti13::ServicesController.new.request_names_and_roles(
        launch_id: lms_instance.id,
        access_token: access_token,
        platform_jwt: @id_token,
        kid: @decoded_header['kid']
      )
  
      puts "NRPS service response: #{response.inspect}"
  
      if response[:status] == :ok && response[:body].present?
        roster = response[:body]
        if roster.is_a?(String)
          roster = JSON.parse(roster)
        end
        if roster && roster['members']
          user_info = roster['members'].find do |member|
            member['user_id'] == lti11_legacy_user_id || member['user_id'] == sub
          end
        end
  
        if user_info
          # Find user by email from the NRPS roster if available
          if user_info['email'].present?
            @user = User.find_by(email: user_info['email'])
            puts "User found by email from NRPS: #{@user.inspect}" if @user
          end
  
          # Create a new user if no matching user is found
          if @user.blank?
            puts "Creating new user from NRPS data"
            @user = User.new(
              email: user_info['email'],
              first_name: user_info['given_name'],
              last_name: user_info['family_name'],
              password: SecureRandom.hex
            )
            unless @user.save
              puts "Failed to create user. Errors: #{@user.errors.full_messages}"
              @message = "OpenDSA: Failed to create user"
              error = Error.new(class_name: 'user_create_fail', message: "Failed to create user #{lti11_legacy_user_id}", params: params.to_s)
              error.save!
              return false
            end
          end
        else
          @message = 'OpenDSA: Unable to uniquely identify user'
          puts @message
          return false
        end
      else
        @message = 'OpenDSA: Failed to retrieve roster'
        puts @message
        return false
      end
    end
  
    sign_in @user
  end

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
