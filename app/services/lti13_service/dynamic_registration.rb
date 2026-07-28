module Lti13Service
  # Lti13Service::DynamicRegistration.new(
  #   openid_configuration: ..., registration_token: ..., base_url: ...
  # ).call
  #
  # Implements the LTI 1.3 Dynamic Registration flow (IMS spec v1.0):
  #   1. Fetch the platform's openid-configuration (passed as a query
  #      param when the platform opens the registration iframe).
  #   2. Validate the issuer against the openid_configuration URL to
  #      prevent impersonation (spec 3.5.1).
  #   3. Generate a per-instance RSA keypair.
  #   4. Find or initialize the LmsInstance row from the platform config.
  #   5. POST the tool configuration to the platform's registration_endpoint
  #      with the registration_token as Bearer.
  #   6. Save the returned client_id + keypair to the LmsInstance.
  #
  # The controller renders a small HTML page that posts
  # `{subject: 'org.imsglobal.lti.close'}` to window.parent so the
  # platform can close the registration iframe.
  class DynamicRegistration
    def initialize(openid_configuration:, registration_token:, base_url:)
      @openid_configuration = openid_configuration
      @registration_token = registration_token
      @base_url = base_url
    end

    def call
      platform_config = fetch_platform_config
      return error('Failed to fetch platform openid-configuration') if platform_config.nil?

      issuer = platform_config['issuer']
      if issuer.blank?
        return error('Platform openid-configuration is missing issuer')
      end
      unless issuer_matches_url?(issuer, @openid_configuration)
        return error("Issuer (#{issuer}) does not match openid_configuration URL (#{@openid_configuration}); aborting to prevent impersonation")
      end

      registration_endpoint = platform_config['registration_endpoint']
      if registration_endpoint.blank?
        return error('Platform openid-configuration is missing registration_endpoint; dynamic registration is not supported by this platform')
      end

      lms_instance = find_or_initialize_lms_instance(issuer, platform_config)

      private_pem, public_pem = generate_keypair

      tool_config = build_tool_config

      registration_response = post_registration(registration_endpoint, tool_config)
      if registration_response.nil?
        return error('Platform rejected the registration request')
      end
      client_id = registration_response['client_id']
      if client_id.blank?
        return error("Platform response did not include client_id: #{registration_response.inspect}")
      end

      lms_instance.client_id = client_id
      lms_instance.private_key = private_pem
      lms_instance.public_key = public_pem
      unless lms_instance.save
        return error("Failed to save LmsInstance: #{lms_instance.errors.full_messages.join(', ')}")
      end

      { success: true, lms_instance: lms_instance }
    rescue => e
      Rails.logger.error "DynamicRegistration error: #{e.class}: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      error("Dynamic registration failed: #{e.message}")
    end

    private

    def fetch_platform_config
      response = Faraday.get(@openid_configuration) do |req|
        req.headers['Accept'] = 'application/json'
      end
      unless response.status == 200
        Rails.logger.error "DynamicRegistration: GET #{@openid_configuration} returned #{response.status}: #{response.body}"
        return nil
      end
      JSON.parse(response.body)
    rescue => e
      Rails.logger.error "DynamicRegistration: error fetching platform config: #{e.message}"
      nil
    end

    # Spec 3.5.1: the openid_configuration URL must be at or below the
    # issuer, to prevent a malicious platform from impersonating another.
    def issuer_matches_url?(issuer, url)
      return false if issuer.blank? || url.blank?
      url == issuer || url.start_with?(issuer + '/')
    rescue
      false
    end

    def find_or_initialize_lms_instance(issuer, platform_config)
      instance = LmsInstance.find_or_initialize_by(url: issuer)
      instance.issuer = issuer
      instance.keyset_url = platform_config['jwks_uri']
      instance.oauth2_url = platform_config['token_endpoint']
      instance.platform_oidc_auth_url = platform_config['authorization_endpoint']
      instance.lms_type = find_or_create_lti13_type
      instance.organization = find_or_create_organization(issuer)
      instance
    end

    def find_or_create_lti13_type
      LmsType.find_or_create_by!(name: 'LTI 1.3')
    end

    # Auto-create an Organization for this issuer if one doesn't already
    # exist. The admin can rename / reclassify it via ActiveAdmin later.
    def find_or_create_organization(issuer)
      host = URI.parse(issuer).host
      name = host
      abbr = host.split('.').first(2).join('.').upcase
      Organization.find_or_create_by!(name: name) do |org|
        org.abbreviation = abbr
      end
    end

    def generate_keypair
      rsa = OpenSSL::PKey::RSA.new(2048)
      [rsa.to_pem, rsa.public_key.to_pem]
    end

    # Tool configuration sent to the platform's registration_endpoint.
    # Advertises OpenDSA's launch URLs, JWKS endpoint, required scopes,
    # and supported LTI message types / placements.
    def build_tool_config
      {
        application_type: 'web',
        response_types: ['id_token'],
        grant_types: ['implicit', 'client_credentials'],
        initiate_login_uri: "#{@base_url}/lti13/login_initiations",
        redirect_uris: ["#{@base_url}/lti13/launches"],
        client_name: 'OpenDSA',
        jwks_uri: "#{@base_url}/lti13/.well-known/jwks",
        token_endpoint_auth_method: 'private_key_jwt',
        scope: [
          'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
          'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
          'https://purl.imsglobal.org/spec/lti-ags/scope/score',
          'https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly'
        ].join(' '),
        'https://purl.imsglobal.org/spec/lti-tool-configuration': {
          domain: URI.parse(@base_url).host,
          description: 'OpenDSA — interactive data structures and algorithms course content',
          target_link_uri: "#{@base_url}/lti13/launches",
          claims: ['iss', 'sub', 'email', 'name', 'given_name', 'family_name'],
          messages: [
            {
              type: 'LtiDeepLinkingRequest',
              target_link_uri: "#{@base_url}/lti13/launches",
              label: 'Select OpenDSA Content',
              placements: ['link_selection', 'assignment_selection'],
              supported_types: ['ltiResourceLink']
            },
            {
              type: 'LtiResourceLinkRequest',
              target_link_uri: "#{@base_url}/lti13/launches",
              placements: ['course_navigation']
            }
          ]
        }
      }
    end

    def post_registration(registration_endpoint, tool_config)
      Rails.logger.info "DynamicRegistration: POSTing to #{registration_endpoint}"
      Rails.logger.info "DynamicRegistration: tool_config jwks_uri=#{tool_config[:jwks_uri]}"
      Rails.logger.info "DynamicRegistration: tool_config redirect_uris=#{tool_config[:redirect_uris]}"
      Rails.logger.info "DynamicRegistration: tool_config initiate_login_uri=#{tool_config[:initiate_login_uri]}"
      Rails.logger.info "DynamicRegistration: FULL tool_config=#{JSON.generate(tool_config)}"
      conn = Faraday.new(url: registration_endpoint)
      response = conn.post do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Accept'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{@registration_token}" if @registration_token.present?
        req.body = JSON.generate(tool_config)
      end
      Rails.logger.info "DynamicRegistration: response status=#{response.status} body=#{response.body}"
      unless [200, 201].include?(response.status)
        Rails.logger.error "DynamicRegistration: POST #{registration_endpoint} returned #{response.status}: #{response.body}"
        return nil
      end
      JSON.parse(response.body)
    rescue => e
      Rails.logger.error "DynamicRegistration: error posting registration: #{e.message}"
      nil
    end

    def error(message)
      { success: false, error: message }
    end
  end
end
