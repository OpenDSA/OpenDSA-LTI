module Lti13Service
  class GetAgsAccessToken
    def initialize(lms_instance)
      @lms_instance = lms_instance
    end

    def call
      puts "Fetching client assertion from ClientCredentialsJwt"
      client_assertion = Lti13Service::ClientCredentialsJwt.new(@lms_instance).call
      puts "Client assertion (JWT): #{client_assertion}"

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

      conn = Faraday.new(url: @lms_instance.oauth2_url) do |faraday|
        faraday.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end

      response = conn.post do |req|
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.body = request_body
      end

      puts "Token request body: #{request_body}"
      puts "Token response status: #{response.status}, body: #{response.body}"

      begin
        if response.success? && response.headers['content-type'].include?('application/json')
          parsed_response = JSON.parse(response.body)
          access_token = parsed_response['access_token']
          puts "Successfully fetched access token from get ags: #{access_token}"
          return parsed_response
        else
          puts "Failed to fetch or invalid content type: and access token from get ags"
          Rails.logger.error "Failed to fetch or invalid content type: Status #{response.status}, Body: #{response.body}"
          return nil
        end
      rescue JSON::ParserError => e
        puts "JSON Parsing Error from get ags"
        Rails.logger.error "JSON Parsing Error: #{e.message} with body: #{response.body}"
        return nil
      end
    end
  end
end
