# module for handling encode/decode of JWT's
module Jwt
  class Encode
    def initialize(payload, rsa_private)
      @payload = payload
      @rsa_private = rsa_private
    end

    def call
      # Ensure rsa_private is an OpenSSL::PKey::RSA object
      rsa_key = ensure_rsa_object(@rsa_private)
      jwk = JWT::JWK.new(rsa_key)
      encoded_jwt = JWT.encode(@payload, jwk.keypair, 'RS256', { kid: jwk.kid })
      puts "JWT encoded successfully: #{encoded_jwt}" # Debugging statement
      return encoded_jwt
    rescue => e
      puts "JWT encoding error: #{e.message}" # Captures and logs any encoding errors
      nil # Return nil or handle the error as appropriate for your application
    end

    private

    # Ensures the rsa_private parameter is a valid OpenSSL::PKey::RSA object
    def ensure_rsa_object(rsa_private)
      return rsa_private if rsa_private.is_a?(OpenSSL::PKey::RSA)
      OpenSSL::PKey::RSA.new(rsa_private) # Attempts to create RSA object from parameter
    rescue OpenSSL::PKey::RSAError => e
      puts "Invalid RSA private key: #{e.message}" # Logs issue with RSA key
      raise # Re-raises the exception to be handled by the caller
    end
  end
end