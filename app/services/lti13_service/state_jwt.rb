# module for handling tool requests
module Lti13Service
    # class fetch platform keys for decode
    # Lti13::DecodePlatformJwt.new(tool, platform_jwt).call
    class StateJwt
      def initialize(lms_instance, additional_jwt_details)
        @lms_instance = lms_instance
        @additional_jwt_details = additional_jwt_details
      end

      def call
        # Dynamically get the host URL from the request to use as the JWT issuer
        # host_url = request.base_url  # You need to ensure that 'request' is accessible here or passed in
      
        payload = {
          iss: @lms_instance.url,
          sub: @lms_instance.client_id,  # Subject, typically the client ID
          aud: @lms_instance.oauth2_url,  # Audience, the OAuth2 token endpoint URL
          iat: Time.now.to_i,  # Issued at: Current time as a Unix timestamp
          exp: Time.now.to_i + 300,  # Expiration time: 300 seconds after issued time
          jti: SecureRandom.hex(10)  # JWT ID: Unique identifier for this token
        }
        @additional_jwt_details.merge!(payload) # Merge any additional JWT details that might have been set externally
        build_jwt(@additional_jwt_details)
      end
      
      def build_jwt(payload)
        # Use @lms_instance to access the instance variable directly
        puts "Checking private key in state_jwt"
        if @lms_instance&.private_key.present?
          rsa_private = OpenSSL::PKey::RSA.new(@lms_instance.private_key)
          jwk = JWT::JWK.new(rsa_private)
          JWT.encode(payload, jwk.keypair, 'RS256', { kid: jwk.kid })
        else
          Rails.logger.error "Private key is missing for LmsInstance ID: #{@lms_instance.id}"
        end
      end

    end
  end