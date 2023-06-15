# module for handling encode/decode of JWT's
module Jwt
  # class for handling encoding of JWT
  # Jwt::Encode.new(payload, rsa_rsa_private).call
  class Header
    def initialize(jwt)
      @jwt = jwt
    end

    def call
      header_segment = @jwt.split('.').first
      JSON.parse(Base64.decode64(header_segment))
    end
  end
end
