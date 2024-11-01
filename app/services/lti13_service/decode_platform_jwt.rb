module Lti13Service
  # Handles fetching platform keys for decoding
  # Lti13Service::DecodePlatformJwt.new(lms_instance, platform_jwt, kid).call
  
  class DecodePlatformJwt
    def initialize(lms_instance, platform_jwt, kid)
      @lms_instance = lms_instance
      @platform_jwt = platform_jwt
      @kid = kid
    end

    def call
      platform_keys = platform_request_for_keys
      deployment_key = platform_keys['keys'].detect { |f| f['kid'] == @kid }

      if deployment_key.nil?
        Rails.logger.info "No deployment key found for KID: #{@kid}"
        return nil #  handle this case better?
      end

      # deployment_key: {"alg"=>"...", "e"=>"...", kid=>"...", "kty"=>"...", "n"=>"...", "use"=>"..."}
      # Convert the deployment key into an RSA public key for decoding
      jwk = JSON::JWK.new(deployment_key)
      rsa_public = jwk.to_key

      algorithm = deployment_key['alg'] || 'RS256' # Fallback to 'RS256' if 'alg' is missing in public key jwk
      Rails.logger.info "Using algorithm: #{algorithm} for decoding."        
      decoded_jwt = JWT.decode(@platform_jwt, rsa_public, true, { algorithm: algorithm })

      Rails.logger.info "JWT decoded successfully."
      decoded_jwt
    rescue => e
      Rails.logger.error "Error decoding JWT: #{e.message}"
      nil # handle this case better
    end


    #~ Private methods ..........................................................
    private

    # Fetch the platform keys required to decode the JWT
    def platform_request_for_keys
      response = Lti13Service::Keys.new(@lms_instance.keyset_url).call
      if response
        Rails.logger.info "Platform keys fetched successfully."
        response 
      else
        Rails.logger.error "Failed to fetch platform keys."
        {}
      end
    end
  end
end
