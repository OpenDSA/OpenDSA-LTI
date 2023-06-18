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
        rsa_private = @lms_instance.openssl_private_key
        jwk = JWT::JWK.new(rsa_private)
        JWT.encode(payload, jwk.keypair, 'RS256', { kid: jwk.kid })
      end
    end
  end