# module for handling platform requests
module Lti13Service
  # LtiPlatform::GetAgsAccessToken.new(lms_instance).call
  class GetAgsAccessToken
    def initialize(lms_instance)
      @lms_instance = lms_instance
    end

    def call
      # It stands to reason, one could post this as json (since we are getting json back)
      # This works (from ref impl perspective), but we replaced with form encoded for now to use w IMS auth server.
      # conn = Faraday.new(url: @lms_instance.oauth2_url)
      # token_request = conn.post do |request|
      #   request.headers['Content-Type'] = 'application/json;charset=UTF-8'
      #   request.body = body.to_json
      # end
      # JSON.parse(token_request.body)

      conn = Faraday.new(url: @lms_instance.oauth2_url) do |faraday|
        faraday.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end

      request = conn.post @lms_instance.oauth2_url, body
      JSON.parse(request.body)
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
