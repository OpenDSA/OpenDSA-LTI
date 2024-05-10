# module for handling platform requests
module Lti13Service
  # LtiPlatform::GetAgsAccessToken.new(tool).call
  class GetAgsAccessToken
    def initialize(lms_instance)
      @lms_instance = lms_instance
    end

    def call
      conn = Faraday.new(url: @lms_instance.oauth2_url) do |faraday|
        faraday.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end
    
      response = conn.post(@lms_instance.oauth2_url, body)
      begin
        if response.success? && response.headers['content-type'].include?('application/json')
          # Safely parse the JSON response
          puts "sucess from getagstoken from call method"
          parsed_response = JSON.parse(response.body)
        else
          # Log an error if the response is not successful or not JSON
          Rails.logger.error "Failed to fetch or invalid content type: Status #{response.status}, Body: #{response.body}"
          return nil
        end
      rescue JSON::ParserError => e
        # Handle JSON parsing errors
        Rails.logger.error "JSON Parsing Error: #{e.message} with body: #{response.body}"
        return nil
      end
      parsed_response
    end
    

    def body
      client_assertion = Lti13Service::ClientCredentialsJwt.new(@lms_instance).call
      {
        grant_type: 'client_credentials',
        client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
        scope:  "#{Rails.configuration.lti_claims_and_scopes['ags_scope_line_item']}"\
                " #{Rails.configuration.lti_claims_and_scopes['ags_scope_result']}"\
                " #{Rails.configuration.lti_claims_and_scopes['ags_scope_score']}"\
                " #{Rails.configuration.lti_claims_and_scopes['proctoring_access_token_scope']}"\
                " #{Rails.configuration.lti_claims_and_scopes['names_and_roles_scope']}"\
                " #{Rails.configuration.lti_claims_and_scopes['proctoring_access_token_scope']}",
        client_assertion: client_assertion
      }
    end
  end
end
