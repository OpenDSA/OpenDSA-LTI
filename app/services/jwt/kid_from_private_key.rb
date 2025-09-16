# module for handling encode/decode of JWT's
module Jwt
    # class for handling encoding of JWT
    # Jwt::Encode.new(payload, rsa_rsa_private).call
    class KidFromPrivateKey
      def initialize(rsa_private)
        @rsa_private = rsa_private
        Rails.logger.info "KID from private class service"
      end
  
      def call
        private_key = OpenSSL::PKey::RSA.new(@rsa_private)
        public_key = private_key.public_key
        JWT::JWK.new(public_key).kid
      end
    end
  end