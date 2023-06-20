# module for handling encode/decode of JWT's
module Jwt
    # class for handling decoding of JWT
    # Jwt::Decode.new(token, rsa_public).call
    class Decode
      def initialize(token, rsa_public)
        @token = token
        @rsa_public = rsa_public
      end
  
      def call
        JWT.decode(@token, @rsa_public, true, {algorithm: 'RS256'})
      end
    end
  end