class Lti13::LaunchesController < ApplicationController
  include Lti13::LaunchesHelper
  layout 'lti13', only: [:create]
  before_action :set_lms_instance, only: [:index, :show]
  before_action :set_launch, only: [:show, :edit, :update, :destroy]
  after_action :allow_iframe, only: [:create, :handle_resource_link_request]

  # GET /launches
  def index
    @launches = @lms_instance.lti_launches
  end

  # GET /launches/1
  def show
    Rails.application.executor.wrap { @access_token = @lms_instance.oauth2_url.present? ? Lti13Service::GetAgsAccessToken.new(@lms_instance).call : nil }
  end

  # GET /launches/new
  def new
    @launch = LtiLaunch.new
  end

  # GET /launches/1/edit
  def edit; end

  # POST /launches
  def create
    # If this is an LTI 1.1 launch (no id_token, but has oauth_consumer_key),
    # forward to the LTI 1.1 controller so grade passback works correctly
    if params[:id_token].blank? && params[:oauth_consumer_key].present?
      Rails.logger.info "LTI 1.1 launch detected at /lti13/launches, forwarding to LtiController#launch"
      Rails.logger.debug "LTI 1.1 forwarding: current_user before forward = #{current_user&.id.inspect}"
      Rails.logger.debug "LTI 1.1 forwarding: launch params user_id=#{params[:user_id].inspect} roles=#{params[:roles].inspect}"
      status, headers, body = LtiController.action(:launch).call(request.env)
      response.status = status
      headers.each { |k, v| response.headers[k] = v }
      self.response_body = body
      return
    end

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
        if @lms_instance.nil?
          Rails.logger.error "LaunchesController#create: LmsInstance not found for tool_id=#{tool_id}"
          render plain: "LMS instance not found", status: :not_found
          return
        end
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
          render plain: "OpenDSA: Failed to retrieve access token from LMS. Check that the tool's public key is registered in Canvas Developer Key settings.", status: :bad_gateway
          return
        end

        unless set_user
          render plain: @message || "Unable to identify user", status: :unauthorized
          return
        end

        if @decoded_jwt
          payload = launch_payload
          message_type = payload['https://purl.imsglobal.org/spec/lti/claim/message_type']
          target_link_uri_log = payload['https://purl.imsglobal.org/spec/lti/claim/target_link_uri']
          placement_log = payload.dig('https://purl.imsglobal.org/spec/lti/claim/launch_presentation', 'placement')
          Rails.logger.info "LTI 1.3 launch: message_type=#{message_type.inspect} placement=#{placement_log.inspect} target_link_uri=#{target_link_uri_log.inspect}"

          if message_type == 'LtiDeepLinkingRequest'
            @launch = LtiLaunch.create!(
              lms_instance_id: @lms_instance.id,
              user_id: @user.id,
              course_offering_id: nil,
              id_token: @id_token,
              decoded_jwt: @decoded_jwt,
              kid: kid,
              expires_at: Time.now + 1.hour
            )
            Rails.logger.info "LTI Deep Linking Launch created with ID: #{@launch.id}"
            handle_deep_linking_request
            return
          end

          target_link_uri = payload['https://purl.imsglobal.org/spec/lti/claim/target_link_uri']
          if target_link_uri.present?
            tl_uri = URI.parse(target_link_uri)
            tl_query = tl_uri.query ? CGI.parse(tl_uri.query) : {}
            tl_inst_book_id = tl_query["custom_inst_book_id"]&.first
            tl_inst_module_id = tl_query["custom_inst_module_id"]&.first
            if tl_inst_book_id.blank? && tl_inst_module_id.present?
              @launch = LtiLaunch.create!(
                lms_instance_id: @lms_instance.id,
                user_id: @user.id,
                course_offering_id: nil,
                id_token: @id_token,
                decoded_jwt: @decoded_jwt,
                kid: kid,
                expires_at: Time.now + 1.hour
              )
              Rails.logger.info "LTI Standalone Module Launch created with ID: #{@launch.id} (inst_module_id=#{tl_inst_module_id})"
              handle_standalone_module_launch(payload, tl_inst_module_id)
              return
            end
          end

          course_offering_id = determine_course_offering_id_from_jwt(@decoded_jwt)
          if course_offering_id.nil?
            render plain: <<-MSG.strip_heredoc, status: :unprocessable_entity
              OpenDSA could not determine which content to display for this
              launch. The target_link_uri contained no custom parameters:
              #{target_link_uri}

              This usually means the Canvas Developer Key has no Deep Linking
              placement configured. Please update the Developer Key in Canvas
              to add a 'Deep Linking' (or 'assignment_selection' /
              'link_selection') placement pointing to:
              #{request.protocol}#{request.host_with_port}/lti13/launches

              Then re-add the assignment from within Canvas — you should see
              the OpenDSA content picker.
            MSG
            return
          end

          @launch = LtiLaunch.create!(
            lms_instance_id: @lms_instance.id,
            user_id: @user.id,
            course_offering_id: course_offering_id,
            id_token: @id_token,
            decoded_jwt: @decoded_jwt,
            kid: kid,
            expires_at: Time.now + 1.hour
          )
          Rails.logger.info "LTI Launch created successfully with ID: #{@launch.id} for course offering ID: #{course_offering_id}"
          handle_message_type(@decoded_jwt)
        end
      end
    else
      Rails.logger.error "LaunchesController#create: ID token missing"
    end
  end


  def determine_course_offering_id_from_jwt(decoded_jwt)
    decoded_jwt = launch_payload(decoded_jwt)
    target_link_uri = decoded_jwt["https://purl.imsglobal.org/spec/lti/claim/target_link_uri"]
    uri = URI.parse(target_link_uri)
    query_params = uri.query ? CGI.parse(uri.query) : {}
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
  def launch_payload(jwt = @decoded_jwt)
    return nil if jwt.nil?
    jwt = (JSON.parse(jwt) rescue nil) if jwt.is_a?(String)
    jwt.is_a?(Array) ? jwt.first : jwt
  end

  def handle_message_type(decoded_jwt)
    payload = launch_payload(decoded_jwt)
    message_type = payload['https://purl.imsglobal.org/spec/lti/claim/message_type']
    case message_type
    when 'LtiResourceLinkRequest'
      handle_resource_link_request
    when 'LtiDeepLinkingRequest'
      handle_deep_linking_request
    else
      render 'error', status: :unprocessable_entity
    end
  end

  def handle_resource_link_request
    decoded_jwt = launch_payload
    target_link_uri = decoded_jwt["https://purl.imsglobal.org/spec/lti/claim/target_link_uri"]
    uri = URI.parse(target_link_uri)
    query_params = uri.query ? CGI.parse(uri.query) : {}
    file_name = query_params["custom_module_file_name"]&.first
    book_path = query_params["custom_book_path"]&.first

    inst_book_id = query_params["custom_inst_book_id"]&.first

    @inst_book = InstBook.find_by(id: inst_book_id)

    if @inst_book.nil?
      Rails.logger.error "InstBook not found with ID: #{inst_book_id}"
      render plain: "InstBook not found (custom_inst_book_id missing or invalid). Use Deep Linking to select OpenDSA content.", status: :not_found and return
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
      launch_lms_instance = LmsInstance.find_by(client_id: client_id)
      lms_access_id = nil
      if launch_lms_instance
        lms_access_id = LmsAccess.where(lms_instance_id: launch_lms_instance.id, user_id: current_user.id).first&.id
      end
      OdsaModuleProgress.get_progress(current_user.id,
                                      query_params["custom_inst_chapter_module_id"]&.first,
                                      query_params["custom_inst_book_id"]&.first,
                                      decoded_jwt.dig("https://purl.imsglobal.org/spec/lti-ags/claim/endpoint", "lineitem"),
                                      decoded_jwt["sub"],
                                      lms_access_id,
                                      @launch&.id)
      Rails.logger.info "Retrieved user's progress"
      render 'launch', layout: 'lti13', locals: { id_token: params[:id_token], kid: @decoded_header['kid'] } and return
    else
      render plain: "File name or book path not found!", status: :unprocessable_entity and return
    end
  end

  def handle_standalone_module_launch(decoded_jwt, inst_module_id)
    inst_module = InstModule.find_by(id: inst_module_id)
    if inst_module.nil?
      Rails.logger.error "Standalone launch: InstModule not found with id #{inst_module_id}"
      render plain: "OpenDSA module not found (inst_module_id=#{inst_module_id}).", status: :not_found and return
    end

    version = inst_module.current_version
    if version.nil?
      Rails.logger.error "Standalone launch: InstModule #{inst_module_id} has no current_version"
      render plain: "OpenDSA module has no published version.", status: :not_found and return
    end

    file_path = version.file_path
    if file_path.blank? || !File.exist?(file_path)
      Rails.logger.error "Standalone launch: HTML file not found for module=#{inst_module_id}, version=#{version.id}, file_path=#{file_path.inspect}"
      render plain: "OpenDSA module content file not found.", status: :not_found and return
    end
    Rails.logger.info "Standalone launch: module=#{inst_module_id}, version=#{version.id}, file_path=#{file_path}"
    section_html = File.read(file_path)

    match1 = section_html.gsub!(%r{<h(\d+)></h\1></section></div></body></html>(.+?)(<a class="headerlink"[^>]*>[^<]*</a>)}, '<h\1>\2\3</h\1>')
    match2 = section_html.gsub!(%r{<h(\d+)>(.*?)</h\1></section>(.+?)(<a class="headerlink"[^>]*>[^<]*</a>)}, '<h\1>\2\3\4</h\1>')
    if match1.nil? && match2.nil?
      Rails.logger.warn "Standalone launch: neither heading-fixup regex matched for module=#{inst_module_id}, version=#{version.id} (Sphinx output format may have changed)"
    end

    client_id = decoded_jwt["aud"]
    launch_lms_instance = LmsInstance.find_by(client_id: client_id)
    lms_access_id = nil
    if launch_lms_instance
      lms_access_id = LmsAccess.where(lms_instance_id: launch_lms_instance.id, user_id: current_user.id).first&.id
    end

    @course_offering = find_or_create_standalone_course_offering(decoded_jwt)
    if @course_offering
      lti_enroll(@course_offering)
    end

    OdsaModuleProgress.get_standalone_progress(
      current_user.id,
      version.id,
      decoded_jwt.dig("https://purl.imsglobal.org/spec/lti-ags/claim/endpoint", "lineitem"),
      decoded_jwt["sub"],
      lms_access_id,
      @launch&.id
    )
    Rails.logger.info "Retrieved user's standalone module progress"

    exercises = {}
    version.inst_module_section_exercises.includes(:inst_exercise).each do |obj|
      ex_data = {
        'inst_module_section_exercise_id' => obj.id,
        'inst_module_version_id' => obj.inst_module_version_id,
        'inst_module_section_id' => obj.inst_module_section_id,
        'points' => obj.points,
        'threshold' => obj.threshold,
        'required' => obj.required,
        'options' => obj.options,
        'short_name' => obj.inst_exercise.short_name,
        'long_name' => obj.inst_exercise.name,
        'type' => obj.inst_exercise.ex_type,
        'learning_tool' => obj.inst_exercise.learning_tool,
      }
      unless ex_data['learning_tool'].blank?
        extrtool_launch_base_url = request.protocol + request.host_with_port + "/lti/launch_extrtool"
        ex_data['launch_url'] = "#{extrtool_launch_base_url}/#{obj.id}?context_type=standalone-module"
      end
      exercises[ex_data['short_name']] = ex_data
    end

    tp_data = {
      'toParams' => { 'launch_params' => {} },
      'exerciseSettings' => exercises,
      'decodedJwt' => {
        'messageType' => decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/message_type'].to_s,
        'resourceLinkId' => decoded_jwt.dig('https://purl.imsglobal.org/spec/lti/claim/resource_link', 'id').to_s,
        'resourceLinkTitle' => decoded_jwt.dig('https://purl.imsglobal.org/spec/lti/claim/resource_link', 'title').to_s,
        'deploymentId' => decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/deployment_id'].to_s,
        'contextTitle' => decoded_jwt.dig('https://purl.imsglobal.org/spec/lti/claim/context', 'title').to_s,
        'userId' => decoded_jwt['sub'].to_s,
        'legacyUserId' => decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/lti11_legacy_user_id'].to_s
      },
      'instModuleVersionId' => version.id.to_s,
      'instModuleId' => inst_module_id.to_s,
      'moduleTitle' => (decoded_jwt.dig('https://purl.imsglobal.org/spec/lti/claim/resource_link', 'title') || inst_module.name).to_s,
      'userEmail' => current_user.email.to_s,
      'courseOfferingId' => @course_offering&.id.to_s,
      'outcomeService' => false
    }
    tp_json = ERB::Util.json_escape(tp_data.to_json).html_safe

    tp_init = <<-HTML.html_safe
      <script type="application/json" id="odsa-tp-init">#{tp_json}</script>
      <script type="text/javascript">
        (function() {
          var data = document.getElementById('odsa-tp-init');
          var TP = JSON.parse(data.textContent);
          window.ODSA = window.ODSA || {};
          window.ODSA.TP = TP;
        }());
      </script>
    HTML

    style_overrides = <<-CSS.html_safe
      <style type="text/css">
        body { max-width: none !important; margin: 0 !important; padding: 5px !important; }
        div.related { display: none !important; }
      </style>
    CSS

    @section_html = section_html.sub(%r{<head>}, "<head>#{tp_init}#{style_overrides}")

    render 'standalone', layout: false
  end


  # Find or create a CourseOffering for a standalone module launch by
  # extracting the LMS course ID from the NRPS or AGS URL in the JWT.
  # Only instructors/admins can create a new CourseOffering; students
  # launching before an instructor has visited will get nil (the
  # Exercise Overview widget will show "Not available").
  def find_or_create_standalone_course_offering(decoded_jwt)
    lms_course_num = nil

    nrps_url = decoded_jwt.dig("https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice", "context_memberships_url")
    if nrps_url
      match = nrps_url.match(%r{/courses/(\d+)})
      lms_course_num = match[1] if match
    end

    if lms_course_num.nil?
      ags_lineitems = decoded_jwt.dig("https://purl.imsglobal.org/spec/lti-ags/claim/endpoint", "lineitems")
      if ags_lineitems
        match = ags_lineitems.match(%r{/courses/(\d+)})
        lms_course_num = match[1] if match
      end
    end

    # Fall back to context.id if no LMS-specific course number was found
    lms_course_num ||= decoded_jwt.dig("https://purl.imsglobal.org/spec/lti/claim/context", "id")
    if lms_course_num.nil?
      Rails.logger.warn "Standalone launch: could not determine lms_course_num from JWT"
      return nil
    end

    course_offering = CourseOffering.find_by(
      lms_instance_id: @lms_instance.id,
      lms_course_num: lms_course_num.to_s
    )
    return course_offering if course_offering

    # Determine if the launching user is an instructor or admin
    roles = decoded_jwt["https://purl.imsglobal.org/spec/lti/claim/roles"] || []
    is_instructor = roles.include?("http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor") ||
                    roles.include?("http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator")

    unless is_instructor
      Rails.logger.warn "Standalone launch: no CourseOffering for lms_course_num=#{lms_course_num}, user #{current_user.id} is not instructor/admin"
      return nil
    end

    orgid = @lms_instance.organization_id
    if orgid.blank?
      Rails.logger.warn "Standalone launch: LmsInstance #{@lms_instance.id} has no organization_id"
      return nil
    end

    context = decoded_jwt.dig("https://purl.imsglobal.org/spec/lti/claim/context") || {}
    context_label = context["label"] || "LTI"
    context_title = context["title"] || "LTI Course"

    course = Course.find_by(organization_id: orgid, number: context_label)
    if course.blank?
      course = Course.new(
        name: context_title,
        number: context_label,
        organization_id: orgid,
        user_id: current_user.id,
      )
      course.save!
    end

    course_offering = CourseOffering.new(
      course: course,
      term: Term.current_or_next_term,
      label: context_label,
      lms_instance: @lms_instance,
      lms_course_code: "#{context_title} - #{context_label}",
      lms_course_num: lms_course_num.to_s,
    )
    course_offering.save!
    Rails.logger.info "Created CourseOffering #{course_offering.id} for standalone module (lms_course_num=#{lms_course_num})"
    course_offering
  end


  def handle_deep_linking_request
    decoded_jwt = launch_payload

    @deep_link_return_url = decoded_jwt.dig(
      Rails.configuration.lti_claims_and_scopes['deep_linking_claim'],
      'deep_link_return_url'
    )
    if @deep_link_return_url.blank?
      Rails.logger.error "Deep Linking: deep_link_return_url missing from JWT"
      render plain: "Deep Linking return URL not found in launch JWT", status: :unprocessable_entity
      return
    end

    @deep_linking = true
    @hide_gradebook_settings = true
    @launch_url = request.protocol + request.host_with_port + "/lti13/launches"
    module_info = InstModule.get_current_versions_dict()
    @json = module_info.to_json

    @lms_instance_id = @lms_instance.id
    @organization_id = @lms_instance.organization_id
    @lms_course_num = nil
    @lms_course_code = nil
    @course_offering = nil

    render '/lti/resource', layout: 'lti_resource'
  end

  def set_user
    unless @decoded_jwt
      Rails.logger.info "Decoded JWT is nil. Cannot proceed with user setup."
      @message = "Decoded JWT is nil. Cannot proceed with user setup."
      return false
    end

    decoded_jwt = launch_payload
    lti11_legacy_user_id = decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/lti11_legacy_user_id']
    sub = decoded_jwt['sub']
    email = decoded_jwt['email']
    custom_claim = decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/custom']
    email ||= custom_claim['email'] if custom_claim.is_a?(Hash)

    if email.present?
      @user = User.find_by(email: email)
      Rails.logger.info "User found by email: #{@user.inspect}" if @user
    else
      Rails.logger.info "Email not present in JWT"
    end

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

      response = Lti13Service::RequestNamesAndRoles.new(
        launch_id: lms_instance.id,
        access_token: access_token,
        platform_jwt: @id_token,
        kid: @decoded_header['kid']
      ).call
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
        Rails.logger.info @message
        return false
      end
    end
    if @user.nil?
      @message ||= "Unable to identify or create user"
      return false
    end
    sign_in @user
    @current_user = @user
    true
  end

  # Enroll user in Course Offering.
  def lti_enroll(course_offering)
    Rails.logger.info "Starting enrollment process for user #{current_user.id} in course offering ID: #{course_offering.id}"
    # Retrieve roles from the decoded JWT
    roles = launch_payload['https://purl.imsglobal.org/spec/lti/claim/roles']
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

  def set_lms_instance
    @lms_instance = LmsInstance.find_by(id: params[:lms_instance_id] || session[:lms_instance_id])
  end

  def set_launch
    @launch = LtiLaunch.find(params[:id])
  end

  def launch_params
    params.require(:launch).permit(:id_token, :decoded_jwt, :lms_instance_id, :state)
  end

  #same origin issue with X-frame-Options
  def allow_iframe
    response.headers.except! 'X-Frame-Options'
    Rails.logger.debug "Response headers after removing X-Frame-Options: #{response.headers.inspect}"
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
