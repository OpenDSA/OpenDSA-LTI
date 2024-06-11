module Lti13Service
  class ClientCredentialsJwt
    def initialize(lms_instance)
      @lms_instance = lms_instance
    end

    def call
      build_jwt(generate_payload)
    end

    private

    def generate_payload
      {
        iss: @lms_instance.url,
        sub: @lms_instance.client_id,
        aud: @lms_instance.oauth2_url,
        iat: Time.now.to_i,
        exp: Time.now.to_i + 300,
        jti: SecureRandom.hex(10)
      }
    end

    def build_jwt(payload)
      puts "Checking private key in client_credentials_jwt"
      if @lms_instance&.private_key.present?
        rsa_private = OpenSSL::PKey::RSA.new(@lms_instance.private_key)
        if @lms_instance&.public_key.present?
          jwks = JSON.parse(@lms_instance.public_key)
          jwk_data = jwks.is_a?(Array) ? jwks.first : jwks
          kid = jwk_data['kid']
        else
          puts "Public JWKS is missing for LmsInstance ID: #{@lms_instance.id}"
          return nil
        end
        header_params = { alg: 'RS256', typ: 'JWT', kid: kid }
        encoded_jwt = JWT.encode(payload, rsa_private, 'RS256', header_params)
        puts "JWT encoded successfully: #{encoded_jwt}"
        encoded_jwt
      else
        puts "Private key is missing for LmsInstance ID: #{@lms_instance.id}"
        nil
      end
    end
  end
end
