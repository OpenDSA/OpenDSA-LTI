# module for handling encode/decode of JWT's
module Jwt
  # class for handling encoding of JWT
  # Jwt::Encode.new(payload, rsa_rsa_private).call
  class KidFromPrivateKey
    def initialize(rsa_private)
      @rsa_private = rsa_private
    end

    def call
      cert = OpenSSL::PKey::RSA.new(@rsa_private)
      cert.to_jwk['kid']
    end
  end
end
