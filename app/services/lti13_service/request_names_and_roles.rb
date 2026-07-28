module Lti13Service
  class RequestNamesAndRoles
    def initialize(launch_id:, access_token:, platform_jwt:, kid:)
      @launch_id = launch_id
      @access_token = access_token
      @platform_jwt = platform_jwt
      @kid = kid
    end

    def call
      lms_instance = LmsInstance.find_by_id(@launch_id)
      unless lms_instance
        return { error: 'LMS Instance not found', status: :not_found }
      end
      if @access_token.nil?
        access_token_response = Lti13Service::GetAgsAccessToken.new(lms_instance).call
        if access_token_response.is_a?(Hash) && access_token_response['access_token'].present?
          @access_token = access_token_response['access_token']
        else
          Rails.logger.info "Failed to retrieve access token"
          return { error: 'Failed to retrieve access token', status: :internal_server_error }
        end
      end
      decoded_jwt = Lti13Service::DecodePlatformJwt.new(lms_instance, @platform_jwt, @kid).call
      response = Lti13Service::PostNamesRoles.new(@access_token, decoded_jwt).call
      if response.nil?
        return { error: 'Response is nil', status: :internal_server_error }
      end
      if response.status == 204
        { message: "Names and roles request successful", status: :ok }
      elsif (200..299).cover?(response.status)
        { message: "Names and roles request successful", body: JSON.parse(response.body), status: :ok }
      else
        { error: response.body, status: response.status }
      end
    rescue => e
      Rails.logger.info "Error in Lti13Service::RequestNamesAndRoles: #{e.message}"
      { error: e.message, status: :internal_server_error }
    end
  end
end
