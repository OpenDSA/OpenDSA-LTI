module Lti13Service
  # Handles obtaining an AGS access token
  
  class GetAgsAccessToken
    def initialize(lms_instance)
      @lms_instance = lms_instance
    end

    #Fetch the AGS access token
    def call
      Rails.logger.info "Fetching client assertion from ClientCredentialsJwt" 
      client_assertion = Lti13Service::ClientCredentialsJwt.new(@lms_instance).call
      Rails.logger.info "Client assertion (JWT) generated: #{client_assertion}"
      # Build the request body for the token request
      request_body = {
        grant_type: 'client_credentials',
        client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
        scope: [
          Rails.configuration.lti_claims_and_scopes['ags_scope_line_item'],
          Rails.configuration.lti_claims_and_scopes['ags_scope_result'],
          Rails.configuration.lti_claims_and_scopes['ags_scope_score'],
          Rails.configuration.lti_claims_and_scopes['names_and_roles_scope'],
        ].join(" "),
        client_assertion: client_assertion
      }.to_query

      # Establish a connection to the LMS's OAuth2 endpoint using Faraday
      conn = Faraday.new(url: @lms_instance.oauth2_url) do |faraday|
        faraday.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end

      # Send the token request
      response = conn.post do |req|
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.body = request_body
      end

      # Log the request and response details, leave this loggers here, it might be very helpful in debugging ags issues
      Rails.logger.info "Token request body: #{request_body}"
      Rails.logger.info "Token response status: #{response.status}, body: #{response.body}"

      begin
        if response.success? && response.headers['content-type'].include?('application/json')
          parsed_response = JSON.parse(response.body)
          access_token = parsed_response['access_token']
          Rails.logger.info "Successfully fetched access token: #{access_token}"
          return parsed_response
        else
          Rails.logger.error "Failed to fetch or invalid content type: Status #{response.status}, Body: #{response.body}"
          return nil
        end
      rescue JSON::ParserError => e
        Rails.logger.error "JSON Parsing Error: #{e.message} with body: #{response.body}"
        return nil
      end
    end
  end
end
