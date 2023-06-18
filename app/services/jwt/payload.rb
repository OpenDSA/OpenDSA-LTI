# module for handling encode/decode of JWT's
module Jwt
    # class for handling encoding of JWT
    # Jwt::Encode.new(payload, rsa_rsa_private).call
    class Payload
      def initialize(jwt)
        @jwt = jwt
      end

      def call
        payload_segment = @jwt.split('.').second
        JSON.parse(Base64.decode64(payload_segment))
      end
    end
  end