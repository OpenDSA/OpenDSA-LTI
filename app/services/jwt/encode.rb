module Jwt
  class Encode
    def initialize(payload, rsa_private)
      @payload = payload
      @rsa_private = rsa_private
    end

    def call
      # Ensure rsa_private is an OpenSSL::PKey::RSA object
      rsa_key = ensure_rsa_object(@rsa_private)
      kid = KidFromPrivateKey.new(@rsa_private).call
      Rails.logger.info "kid from public key from encode.rb #{kid}"
      if kid.nil?
        Rails.logger.info "Failed to generate kid from private key"
        return nil
      end
      encoded_jwt = JWT.encode(@payload, rsa_key, 'RS256', { kid: kid })
      Rails.logger.info "JWT encoded successfully: #{encoded_jwt}" 
      return encoded_jwt
    rescue => e
      Rails.logger.info "JWT encoding error: #{e.message}" 
      nil 
    end

    private

    # Ensures the rsa_private parameter is a valid OpenSSL::PKey::RSA object
    def ensure_rsa_object(rsa_private)
      return rsa_private if rsa_private.is_a?(OpenSSL::PKey::RSA)
      OpenSSL::PKey::RSA.new(rsa_private) 
    rescue OpenSSL::PKey::RSAError => e
      Rails.logger.info "Invalid RSA private key: #{e.message}" 
      raise
    end
  end
end