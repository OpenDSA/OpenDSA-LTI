# module for handling encode/decode of JWT's
module Jwt
    # class for handling encoding of JWT
    # Jwt::Encode.new(payload, rsa_rsa_private).call
    class Encode
      def initialize(payload, rsa_private)
        @payload = payload
        @rsa_private = rsa_private
      end
  
      def call
        jwk = JWT::JWK.new(@rsa_private)
        JWT.encode(@payload, jwk.keypair, 'RS256', { kid: jwk.kid })
      end
    end
  end