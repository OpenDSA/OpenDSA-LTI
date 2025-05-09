module Jwt
  class Payload
    def initialize(jwt)
      @jwt = jwt
    end

    def call
      payload_segment = @jwt.split('.')[1] # Get the second segment
      JSON.parse(base64_url_decode(payload_segment))
    end

    private

    # Decodes a Base64URL-encoded string
    def base64_url_decode(str)
      str += '=' * (4 - str.length.modulo(4))
      Base64.decode64(str.tr('-_', '+/'))
    end
  end
end