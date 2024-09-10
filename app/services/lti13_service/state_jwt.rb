module Lti13Service
  # class fetch platform keys for decode
  # Lti13::DecodePlatformJwt.new(tool, platform_jwt).call
  class StateJwt
    def initialize(lms_instance, additional_jwt_details)
      @lms_instance = lms_instance
      @additional_jwt_details = additional_jwt_details
    end

    def call
      # A unique identifier for the entity that issued the JWT
      payload = { iss: @lms_instance.url }

      # "client_id" of the OAuth Client
      payload[:sub] = @lms_instance.client_id

      # Authorization server identifier
      payload[:aud] = @lms_instance.oauth2_url

      # Timestamp for when the JWT was created
      payload[:iat] = Time.now.to_i

      # Timestamp for when the JWT should be treated as having expired (after allowing a margin for clock skew)
      payload[:exp] = Time.now.to_i + 300

      # A unique (potentially reusable) identifier for the token
      payload[:jti] = SecureRandom.hex(10)

      @additional_jwt_details.merge!(payload)
      build_jwt(@additional_jwt_details)
    end

    def build_jwt(payload)
      # Use @lms_instance to access the instance variable directly
      if @lms_instance&.private_key.present?
        rsa_private = OpenSSL::PKey::RSA.new(@lms_instance.private_key)
        kid = Jwt::KidFromPrivateKey.new(@lms_instance.private_key).call
        
        if kid.nil?
          Rails.logger.error "Failed to generate kid from private key for LmsInstance ID: #{@lms_instance.id}"
          return nil
        end

        JWT.encode(payload, rsa_private, 'RS256', { kid: kid })
      else
        Rails.logger.error "Private key is missing for LmsInstance ID: #{@lms_instance.id}"
        nil
      end
    end
  end
end