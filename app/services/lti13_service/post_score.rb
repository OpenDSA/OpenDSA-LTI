module Lti13Service
  # Handles posting scores to the LMS/LTI 1.3 platform

  class PostScore
    def initialize(access_token, decoded_jwt, score_details = nil)
      @access_token = access_token
      @decoded_jwt = decoded_jwt.is_a?(Array) ? HashWithIndifferentAccess.new(decoded_jwt.first) : decoded_jwt
      @score_details = score_details
    end

    def call
      conn = Faraday.new(url: url_from_jwt)
      response = conn.post do |request|
        request.headers['Content-Type'] = 'application/vnd.ims.lis.v1.score+json'
        request.headers['Authorization'] = "Bearer #{@access_token}"
        Rails.logger.info "Request Headers set: #{request.headers.inspect}"

        request_body = details_to_request_body.to_json
        Rails.logger.info "Request Body: #{JSON.pretty_generate(JSON.parse(request_body))}"
        request.body = request_body
      end
      Rails.logger.info "Response status: #{response.status}"
      response
    rescue => e
      Rails.logger.error "Error posting score: #{e.message}"
      nil # Handle better ?
    end

    # Extract URL for the line item from the decoded JWT
    def url_from_jwt
      ags_claim = @decoded_jwt["https://purl.imsglobal.org/spec/lti-ags/claim/endpoint"]
      Rails.logger.info "AGS claim from JWT: #{ags_claim.inspect}"     
      if ags_claim.nil?
        Rails.logger.info "Warning: 'endpoint' claim not found in decoded JWT"
        return nil
      end
      line_item_url = ags_claim["lineitem"] + '/scores'
      if line_item_url.nil?
        Rails.logger.info "Warning: 'lineitem' key not found within 'endpoint' claim"
        return nil
      end
      Rails.logger.info "Line item URL: #{line_item_url}"
      line_item_url
    rescue => e
      Rails.logger.error "Error extracting line item URL: #{e.message}"
      nil
    end

   # Build the request body for posting the score
    def details_to_request_body
      {
        timestamp: Time.now.iso8601,  #timestamp must be in this ISO 8601 format
        scoreGiven: @score_details[:scoreGiven] || 0,
        scoreMaximum: @score_details[:scoreMaximum] || 100,
        comment: @score_details[:comment] || nil,
        activityProgress: @score_details[:activityProgress] || 'Completed',
        gradingProgress: @score_details[:gradingProgress] || 'FullyGraded',
        userId: @decoded_jwt['sub'] # The user ID from the JWT

      }
    end
  end
end
