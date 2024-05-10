# module for handling platform requests
module Lti13Service
  class PostNamesRoles
    def initialize(access_token, decoded_jwt)
      @access_token = access_token
      @decoded_jwt = HashWithIndifferentAccess.new(decoded_jwt)
    end

    def call
      conn = Faraday.new(url: url_from_jwt)
      response = conn.get do |request|
        request.headers['Accept'] = 'application/vnd.ims.lti-nrps.v2.membershipcontainer+json'
        request.headers['Authorization'] = "Bearer #{@access_token}"
      end
      handle_response(response)
    end

    private

    def handle_response(response)
      if response.success?
        Rails.logger.info("NRPS Data fetched successfully.")
        JSON.parse(response.body)
      else
        Rails.logger.error("Failed to fetch NRPS data: #{response.status} - #{response.body}")
        nil # Or raise an exception based on your error handling strategy
      end
    end

    def url_from_jwt
      @decoded_jwt[Rails.configuration.lti_claims_and_scopes['names_and_roles_claim']]['context_memberships_url']
    end
  end
end