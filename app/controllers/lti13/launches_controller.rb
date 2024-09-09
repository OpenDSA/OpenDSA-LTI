class Lti13::LaunchesController < ApplicationController
  include Lti13::LaunchesHelper
  layout 'lti13', only: [:create]
  after_action :allow_iframe, only: [:create, :handle_resource_link_request]

  # GET /launches
  def index
    @launches = @lms_instance.launches
  end

  # GET /launches/1
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
  def create
    Rails.logger.info "Starting LTI 1.3 launch process: Launch request params: #{params.inspect}"  
    if params[:id_token]&.present?
      if params[:state]&.present?
        @decoded_payload = Jwt::Payload.new(params[:state]).call
        if @decoded_payload.nil?
          Rails.logger.error "LaunchesController#create: Decoded payload is nil"
          return
        end
        tool_id = @decoded_payload['tool_id']
        @lms_instance = LmsInstance.find_by(id: tool_id.to_i)
      else
        Rails.logger.error "LaunchesController#create: State parameter missing"
        return
      end
  
      @decoded_header = Jwt::Header.new(params[:id_token]).call
      kid = @decoded_header['kid']
      keys_response = Lti13Service::Keys.new(@lms_instance.keyset_url).call
  
      if keys_response.nil?
        Rails.logger.error "LaunchesController#create: Error fetching keys from keyset URL"
      else
        @decoded_jwt = Lti13Service::DecodePlatformJwt.new(@lms_instance, params[:id_token], kid).call
        @id_token = params[:id_token]
        @access_token = Lti13Service::GetAgsAccessToken.new(@lms_instance).call
        Rails.logger.info "access token launches controller#create: access token: #{@access_token}"
  
        if @access_token.nil?
          Rails.logger.error "Failed to retrieve access token in LaunchesController#create"
          return
        end
  
        # Set user based on the decoded JWT claims.
        set_user
  
        if @decoded_jwt
          # Determine the course offering
          course_offering_id = determine_course_offering_id_from_jwt(@decoded_jwt)          
          if course_offering_id.nil?
            render plain: "Course offering not found", status: :unprocessable_entity
            return
          end
  
          # Create the LtiLaunch record
          launch = LtiLaunch.create!(
            lms_instance_id: @lms_instance.id,
            user_id: @user.id,
            course_offering_id: course_offering_id,
            id_token: @id_token,
            decoded_jwt: @decoded_jwt,
            kid: kid,
            expires_at: Time.now + 1.hour
          )
          Rails.logger.info "LTI Launch created successfully with ID: #{launch.id} for course offering ID: #{course_offering_id}"
          handle_message_type(@decoded_jwt)
        end
      end
    else
      Rails.logger.error "LaunchesController#create: ID token missing"
    end
  end
  
 
  def determine_course_offering_id_from_jwt(decoded_jwt)
    decoded_jwt = decoded_jwt.first  
    target_link_uri = decoded_jwt["https://purl.imsglobal.org/spec/lti/claim/target_link_uri"]
    uri = URI.parse(target_link_uri)
    query_params = CGI.parse(uri.query) 
    inst_book_id = query_params["custom_inst_book_id"]&.first
    @inst_book = InstBook.find_by(id: inst_book_id)
    
    if @inst_book.nil?
      Rails.logger.error "InstBook not found with ID: #{inst_book_id}"
      return nil
    end
    
    @course_offering = CourseOffering.find_by(id: @inst_book.course_offering_id)   
    if @course_offering.nil?
      Rails.logger.error "Course offering not found for InstBook ID: #{inst_book_id}"
      return nil
    end   
    return @course_offering.id
  end
  
  #~ Private methods ..........................................................
  private
  # -------------------------------------------------------------
  def handle_message_type(decoded_jwt)
    message_type_claim = decoded_jwt.find { |claim| claim.has_key?('https://purl.imsglobal.org/spec/lti/claim/message_type') }
    message_type = message_type_claim['https://purl.imsglobal.org/spec/lti/claim/message_type']
    case message_type
    when 'LtiResourceLinkRequest'
      handle_resource_link_request
    when 'LtiDeepLinkingRequest'
      handle_deep_linking_request
    else
      render 'error', status: :unprocessable_entity
    end
  end

  # Handle the LTI Resource Link Request then render content.
  def handle_resource_link_request
    decoded_jwt = @decoded_jwt.first  
    target_link_uri = decoded_jwt["https://purl.imsglobal.org/spec/lti/claim/target_link_uri"]
    uri = URI.parse(target_link_uri)
    query_params = CGI.parse(uri.query) 
    file_name = query_params["custom_module_file_name"]&.first
    book_path = query_params["custom_book_path"]&.first  
  
    @inst_book = InstBook.find_by(id: query_params["custom_inst_book_id"].first)
    
    if @inst_book.nil?
      Rails.logger.error "InstBook not found with ID: #{query_params['custom_inst_book_id'].first}"
      render plain: "InstBook not found", status: :not_found and return
    end
    
    @course_offering = CourseOffering.find_by(id: @inst_book.course_offering_id)
    if @course_offering.nil?
      Rails.logger.error "Course offering not found for InstBook ID: #{@inst_book.id}"
      render plain: "Course offering not found", status: :not_found and return
    end
  
    Rails.logger.info "Attempting to enroll user in course offering ID: #{@course_offering.id}"
    lti_enroll(@course_offering)
  
    if file_name && book_path
      file_path = File.join('public/OpenDSA/Books', book_path, '/lti_html/', "#{file_name}.html")
      @section_html = File.read(file_path)
      client_id = decoded_jwt["aud"]
      lms_access_id = LmsAccess.where(consumer_key: client_id).pluck(:id).first
      OdsaModuleProgress.get_progress(current_user.id,
                                      query_params["custom_inst_chapter_module_id"].first,
                                      query_params["custom_inst_book_id"].first,
                                      decoded_jwt.dig("https://purl.imsglobal.org/spec/lti-ags/claim/endpoint", "lineitem"),
                                      decoded_jwt["sub"],
                                      lms_access_id)
      Rails.logger.info "Retrieved user's progress"
      render 'launch', layout: 'lti13', locals: { id_token: params[:id_token], kid: @decoded_header['kid'] } and return
    else
      render plain: "File name or book path not found!", status: :unprocessable_entity and return
    end
  end 

  # Set the user from decoded JWT info.
  def set_user
    unless @decoded_jwt
      # Rails.logger.error "Decoded JWT is nil. Cannot proceed with user setup."
      Rails.logger.info "Decoded JWT is nil. Cannot proceed with user setup."
      render 'error' and return
    end

    decoded_jwt = @decoded_jwt.first
    lti11_legacy_user_id = decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/lti11_legacy_user_id']
    sub = decoded_jwt['sub']
    email = decoded_jwt.dig('https://purl.imsglobal.org/spec/lti/claim', 'email')
    
    if email.present?
      @user = User.find_by(email: email)
      Rails.logger.info "User found by email: #{@user.inspect}" if @user
    else
      Rails.logger.info "Email not present in JWT"
    end

    # If user is not found, proceed to check via NRPS 
    if @user.blank?
      Rails.logger.info "User not found by email, checking NRPS service"
      lms_instance = @lms_instance
      access_token_response = Lti13Service::GetAgsAccessToken.new(lms_instance).call
      access_token = access_token_response['access_token'] if access_token_response
  
      if access_token.blank?
        Rails.logger.info "Failed to retrieve access token"
        @message = 'OpenDSA: Failed to retrieve access token'
        return false
      end
  
      response = Lti13::ServicesController.new.request_names_and_roles(
        launch_id: lms_instance.id,
        access_token: access_token,
        platform_jwt: @id_token,
        kid: @decoded_header['kid']
      )
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
          # Find user from the NRPS roster
          if user_info['email'].present?
            @user = User.find_by(email: user_info['email'])
            Rails.logger.info "User found from NRPS: #{@user.inspect}" if @user
          end  
          # Create user if no matching user is found
          if @user.blank?
            begin
              @user = User.create!(
                email: user_info['email'] || "#{lms_instance.id}_#{user_info['user_id']}@#{lms_instance.url}",
                first_name: user_info['given_name'],
                last_name: user_info['family_name'],
                password: SecureRandom.hex
              )
            rescue ActiveRecord::RecordInvalid => e
              if e.message.include?("Email has already been taken")
                @user = User.find_by(email: "#{lms_instance.id}_#{user_info['user_id']}@#{lms_instance.url}")
                Rails.logger.info "User already exists, retrieved existing user: #{@user.inspect}"
              else
                Rails.logger.info "Failed to create user. Errors: #{e.message}"
                @message = "OpenDSA: Failed to create user"
                error = Error.new(class_name: 'user_create_fail', message: "Failed to create user #{user_info['user_id']}", params: params.to_s)
                error.save!
                return false
              end
            end
          end
        else
          email = "#{lms_instance.id}_#{lti11_legacy_user_id || sub}@#{lms_instance.url}"
          begin
            @user = User.create!(
              email: email,
              first_name: decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/lis_person_name_given'],
              last_name: decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/lis_person_name_family'],
              password: SecureRandom.hex
            )
          rescue ActiveRecord::RecordInvalid => e
            if e.message.include?("Email has already been taken")
              @user = User.find_by(email: email)
              Rails.logger.info "User already exists, retrieved existing user: #{@user.inspect}"
            else
              Rails.logger.info "Failed to create user. Errors: #{e.message}"
              @message = "OpenDSA: Failed to create user"
              error = Error.new(class_name: 'user_create_fail', message: "Failed to create user #{email}", params: params.to_s)
              error.save!
              return false
            end
          end
        end
      else
        @message = 'OpenDSA: Failed to retrieve roster'
        puts @message
        return false
      end
    end
    sign_in @user
  end

  # Enroll user in Course Offering.
  def lti_enroll(course_offering)
    Rails.logger.info "Starting enrollment process for user #{current_user.id} in course offering ID: #{course_offering.id}"
    # Retrieve roles from the decoded JWT
    roles = @decoded_jwt.first['https://purl.imsglobal.org/spec/lti/claim/roles']
    Rails.logger.debug "Roles retrieved from JWT: #{roles.inspect}"
    role = roles.include?("http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor") ? CourseRole.instructor : CourseRole.student
    Rails.logger.debug "Determined role for user #{current_user.id}: #{role.name}"

    # Check if user can enroll and is not already enrolled
    if course_offering.can_enroll?
      Rails.logger.info "Course offering ID: #{course_offering.id} allows enrollment."
      unless course_offering.is_enrolled?(current_user)
        Rails.logger.info "User #{current_user.id} is not already enrolled. Proceeding with enrollment."
        enrollment = CourseEnrollment.create(
          course_offering: course_offering,
          user: current_user,
          course_role: role
        )
        if enrollment.persisted?
          Rails.logger.info "User #{current_user.id} successfully enrolled in course offering ID: #{course_offering.id} with role #{role.name}."
        else
          Rails.logger.error "Failed to enroll user #{current_user.id} in course offering ID: #{course_offering.id}. Enrollment details: #{enrollment.errors.full_messages}"
        end
      else
        Rails.logger.warn "User #{current_user.id} is already enrolled in course offering ID: #{course_offering.id}."
      end
    else
      Rails.logger.warn "Course offering ID: #{course_offering.id} does not allow enrollment."
    end

    # If user is already enrolled, check if the role needs to be updated
    if course_offering.is_enrolled?(current_user)
      Rails.logger.info "Checking if the role for user #{current_user.id} in course offering ID: #{course_offering.id} needs to be updated."
      ce = CourseEnrollment.find_by(course_offering_id: course_offering.id, user_id: current_user.id)
      if ce.course_role != role
        Rails.logger.info "Role mismatch detected for user #{current_user.id}. Updating role to #{role.name}."
        ce.course_role = role
        if ce.save
          Rails.logger.info "User #{current_user.id}'s role updated to #{role.name} in course offering ID: #{course_offering.id}."
        else
          Rails.logger.error "Failed to update user #{current_user.id}'s role in course offering ID: #{course_offering.id}. Update details: #{ce.errors.full_messages}"
        end
      else
        Rails.logger.info "User #{current_user.id} already has the correct role #{role.name} in course offering ID: #{course_offering.id}."
      end
    end
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
