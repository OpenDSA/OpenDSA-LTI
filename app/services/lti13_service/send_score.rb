module Lti13Service
  class SendScore
    def initialize(launch_id:, access_token:, platform_jwt:, kid:, highest_score:, lineitem_url: nil, user_id: nil)
      @launch_id = launch_id
      @access_token = access_token
      @platform_jwt = platform_jwt
      @kid = kid
      @highest_score = highest_score
      @lineitem_url = lineitem_url
      @user_id = user_id
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

      if @lineitem_url.present? && @user_id.present?
        Rails.logger.info "Attempting to post score (using stored lineitem URL)..."
        response = Lti13Service::PostScore.new(
          @access_token, nil,
          { highest_score: @highest_score },
          lineitem_url: @lineitem_url,
          user_id: @user_id
        ).call
      else
        decoded_jwt = Lti13Service::DecodePlatformJwt.new(lms_instance, @platform_jwt, @kid).call
        Rails.logger.info "Attempting to post score..."
        response = Lti13Service::PostScore.new(@access_token, decoded_jwt, { highest_score: @highest_score }).call
      end

      if response.nil?
        return { error: 'Response is nil', status: :internal_server_error }
      end
      Rails.logger.info "Response status: #{response.status}"

      if response.status == 204
        Rails.logger.info "Score submission successful"
        { message: "Score submission successful", status: :ok }
      elsif (200..299).cover?(response.status)
        Rails.logger.info "Score submission successful with response: #{response.body}"
        { body: JSON.parse(response.body), status: :ok }
      else
        Rails.logger.info "** Error submitting score! Response status: #{response.status}, Response body: #{response.body}"
        { body: JSON.parse(response.body), status: :unprocessable_entity }
      end
    rescue => e
      Rails.logger.info "Error in Lti13Service::SendScore: #{e.message}"
      { error: e.message, status: :internal_server_error }
    end
  end
end
