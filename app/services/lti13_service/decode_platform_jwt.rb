module Lti13Service
  class DecodePlatformJwt
    def initialize(lms_instance, platform_jwt, kid)
      @lms_instance = lms_instance
      @platform_jwt = platform_jwt
      @kid = kid
      puts "Initializing DecodePlatformJwt with JWT: #{@platform_jwt}, KID: #{@kid}"
    end

    def call
      puts "Starting the JWT decode process."
      platform_keys = platform_request_for_keys
      puts "Platform keys fetched: #{platform_keys}"

      deployment_key = platform_keys['keys'].detect { |f| f['kid'] == @kid }
      puts "Deployment key found: #{deployment_key}"

      if deployment_key.nil?
        puts "No deployment key found for KID: #{@kid}"
        return nil # Or handle this case as needed
      end

      jwk = JSON::JWK.new(deployment_key)
      rsa_public = jwk.to_key
      puts "Converted JWK to RSA public key."

      decoded_jwt = JWT.decode(@platform_jwt, rsa_public, true, { algorithm: deployment_key['alg'] })
      puts "JWT decoded successfully: #{decoded_jwt}"

      decoded_jwt
    rescue => e
      puts "Error decoding JWT: #{e.message}"
      nil # Return nil or handle the error as needed
    end

    private

    def platform_request_for_keys
      response = Lti13Service::Keys.new(@lms_instance.keyset_url).call
      if response
        puts "Platform request for keys successfully ran."
        response 
      else
        puts "Failed to fetch platform keys: #{response.status}"
        {}
      end
    end
  end
end

