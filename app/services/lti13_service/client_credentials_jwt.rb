module Lti13Service
  class ClientCredentialsJwt
    def initialize(lms_instance)
      @lms_instance = lms_instance
    end

    def call
      jwt = build_jwt(generate_payload)
      fetch_access_token(jwt) if jwt
    end

    private

    def generate_payload
      # host_url = request.base_url  #  dynamically get the host URL
      {
        iss: @lms_instance.url,
        sub: @lms_instance.client_id,  
        aud: @lms_instance.oauth2_url,  # The audience, which is the OAuth2 URL of the platform
        iat: Time.now.to_i,  # Issued at: Current time in seconds since the Unix epoch
        exp: Time.now.to_i + 300,  # Expiration time: 300 seconds after the issued time
        jti: SecureRandom.hex(10)  # JWT ID: A randomly generated identifier for this JWT
      }
    end
    
    def build_jwt(payload)
      puts "Checking private key in client_credentials_jwt"
      if @lms_instance&.private_key.present?
        # Use the private key directly from your secure storage
        rsa_private = OpenSSL::PKey::RSA.new(@lms_instance.private_key)
        
        # Use the JWKS to get the kid
        if @lms_instance&.public_key.present?
          jwks = JSON.parse(@lms_instance.public_key)
          jwk_data = jwks.is_a?(Array) ? jwks.first : jwks
          kid = jwk_data['kid']
        else
          puts "Public JWKS is missing for LmsInstance ID: #{@lms_instance.id}"
          return nil
        end
    
        header_params = { alg: 'RS256', typ: 'JWT', kid: kid }
        encoded_jwt = JWT.encode(payload, rsa_private, 'RS256', header_params)
    
        puts "JWT encoded successfully: #{encoded_jwt}"
        encoded_jwt
      else
        puts "Private key is missing for LmsInstance ID: #{@lms_instance.id}"
        nil
      end
    end
    
    
    def fetch_access_token(jwt)
      request_body = {
        grant_type: 'client_credentials',
        client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
        client_assertion: jwt,
        scope: [
          Rails.configuration.lti_claims_and_scopes['ags_scope_line_item'],
          Rails.configuration.lti_claims_and_scopes['ags_scope_result'],
          Rails.configuration.lti_claims_and_scopes['ags_scope_score'],
          Rails.configuration.lti_claims_and_scopes['names_and_roles_scope'],
          Rails.configuration.lti_claims_and_scopes['proctoring_access_token_scope']
        ].join(" ")
      }.to_query  # Convert to query string format

      conn = Faraday.new(url: @lms_instance.oauth2_url)
      response = conn.post do |req|
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.body = request_body
      end

      puts "Token request body: #{request_body}"  # Log the full request body
      puts "Token response status: #{response.status}, body: #{response.body}"

      if response.status == 200
        access_token_info = JSON.parse(response.body)
        puts "Access Token fetched successfully: #{access_token_info}"
        access_token_info
      else
        puts "Error fetching access token: #{response.status} - #{response.body}"
        nil
      end
    end
  end
end

