module Jwt
  class Header
    def initialize(jwt)
      @jwt = jwt
    end

    def call
      header_segment = @jwt.split('.').first
      JSON.parse(base64_url_decode(header_segment))
    end

    private

    # Decodes a Base64URL-encoded string
    def base64_url_decode(str)
      str += '=' * (4 - str.length.modulo(4))
      Base64.decode64(str.tr('-_', '+/'))
    end
  end
end