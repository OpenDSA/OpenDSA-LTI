module Lti13Service
  # Handles the creation of a client credentials JWT using the LMS instance's private key.
  # The JWT is used for OAuth2 authentication.
  
  class ClientCredentialsJwt
    def initialize(lms_instance)
      @lms_instance = lms_instance
    end

    def call
      build_jwt(generate_payload)
    end

    #~ Private methods ..........................................................
    private
   
    # Generate the payload for the JWT. 
    def generate_payload
      {
        iss: @lms_instance.client_id,
        sub: @lms_instance.client_id,
        aud: @lms_instance.oauth2_url,
        iat: Time.now.to_i,
        exp: Time.now.to_i + 300,
        jti: SecureRandom.hex(10)
      }
    end

    # Build the JWT using the payload and the LMS instance's private key.
    def build_jwt(payload)
      if @lms_instance&.private_key.present?
        rsa_private = OpenSSL::PKey::RSA.new(@lms_instance.private_key)
        kid = Jwt::KidFromPrivateKey.new(@lms_instance.private_key).call
        Rails.logger.info "KID from public key from client #{kid}"

        if kid.nil?
          Rails.logger.info "Failed to generate kid from private key for LmsInstance ID: #{@lms_instance.id}"
          return nil
        end
        header_params = { alg: 'RS256', typ: 'JWT', kid: kid }        
        encoded_jwt = JWT.encode(payload, rsa_private, 'RS256', header_params)
        Rails.logger.info "JWT encoded successfully: #{encoded_jwt}"
        encoded_jwt
      else
        Rails.logger.info "Private key is missing for LmsInstance ID: #{@lms_instance.id}"
        nil
      end
    end
  end
end
