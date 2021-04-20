# module for handling lms_instance requests
module Lti13Service
    # class fetch platform keys for decode
    # Lti13::DecodePlatformJwt.new(lms_instance, platform_jwt).call
    class DecodePlatformJwt
      def initialize(lms_instance, platform_jwt, kid)
        @lms_instance = lms_instance
        @platform_jwt = platform_jwt
        @kid = kid
      end


      def call
        platform_keys = plaform_request_for_keys
        deployment_key = platform_keys['keys'].detect { |f| f['kid'] == @kid }

        # deployment_key: {"alg"=>"...", "e"=>"...", kid=>"...", "kty"=>"...", "n"=>"...", "use"=>"..."}
        jwk = JSON::JWK.new(deployment_key)

        # TODO: shouldn't have to do this, need to remove (dev platform was returning lowercase)
        jwk['kty'] = 'RSA'

        # returns an OpenSSL::PKey::RSA, which is what JWT.decode expects
        rsa_public = jwk.to_key

        # decode JWT
        Jwt::Decode.new(@platform_jwt, rsa_public).call
      end

      def plaform_request_for_keys
        request = Lti13Service::Keys.new(@lms_instance).call
        JSON.parse(request.body)
      end
    end
  end
