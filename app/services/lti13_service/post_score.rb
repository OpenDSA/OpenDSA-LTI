module Lti13Service
  class PostScore
    def initialize(access_token, decoded_jwt, score_details = nil, lineitem_url: nil, user_id: nil)
      @access_token = access_token
      @decoded_jwt = decoded_jwt.is_a?(Array) ? HashWithIndifferentAccess.new(decoded_jwt.first) : decoded_jwt
      @lineitem_url = lineitem_url
      @user_id = user_id
      @score_details = normalize_score_details(score_details)
    end

    def normalize_score_details(score_details)
      details = score_details.is_a?(Hash) ? HashWithIndifferentAccess.new(score_details) : {}
      if details.key?(:highest_score) || details.key?('highest_score')
        highest = details[:highest_score].to_f
        details[:scoreGiven]       = highest unless details.key?(:scoreGiven) || details.key?('scoreGiven')
        details[:scoreMaximum]     = 100     unless details.key?(:scoreMaximum) || details.key?('scoreMaximum')
        details[:activityProgress] = 'Completed' unless details.key?(:activityProgress) || details.key?('activityProgress')
        details[:gradingProgress]  = 'FullyGraded'  unless details.key?(:gradingProgress) || details.key?('gradingProgress')
      end
      details
    end

    private :normalize_score_details

    def call
      url = url_from_jwt
      return nil if url.nil?
      conn = Faraday.new(url: url)
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

    def url_from_jwt
      if @lineitem_url.present?
        Rails.logger.info "Line item URL (from progress row): #{@lineitem_url}"
        return @lineitem_url + '/scores'
      end

      ags_claim = @decoded_jwt["https://purl.imsglobal.org/spec/lti-ags/claim/endpoint"]
      Rails.logger.info "AGS claim from JWT: #{ags_claim.inspect}"
      if ags_claim.nil?
        Rails.logger.info "Warning: 'endpoint' claim not found in decoded JWT"
        return nil
      end
      lineitem = ags_claim["lineitem"]
      if lineitem.nil?
        Rails.logger.info "Warning: 'lineitem' key not found within 'endpoint' claim"
        return nil
      end
      line_item_url = lineitem + '/scores'
      Rails.logger.info "Line item URL: #{line_item_url}"
      line_item_url
    rescue => e
      Rails.logger.error "Error extracting line item URL: #{e.message}"
      nil
    end

    def details_to_request_body
      {
        timestamp: Time.now.iso8601,
        scoreGiven: @score_details[:scoreGiven] || 0,
        scoreMaximum: @score_details[:scoreMaximum] || 100,
        comment: @score_details[:comment] || nil,
        activityProgress: @score_details[:activityProgress] || 'Completed',
        gradingProgress: @score_details[:gradingProgress] || 'FullyGraded',
        userId: user_id_for_body
      }
    end

    private

    def user_id_for_body
      return @user_id if @user_id.present?
      @decoded_jwt ? @decoded_jwt['sub'] : nil
    end
  end
end
