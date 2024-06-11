module Lti13Service
  class PostScore
    def initialize(access_token, decoded_jwt, score_details = nil)
      @access_token = access_token
      puts "PostScore initialized with access token: #{@access_token}"

      @decoded_jwt = decoded_jwt.is_a?(Array) ? HashWithIndifferentAccess.new(decoded_jwt.first) : decoded_jwt
      @score_details = score_details
      puts "Decoded JWT in PostScore initialization: #{@decoded_jwt.inspect}"
    end

    def call
      puts "PostScore call method invoked"
      conn = Faraday.new(url: url_from_jwt)
      response = conn.post do |request|
        request.headers['Content-Type'] = 'application/vnd.ims.lis.v1.score+json'
        request.headers['Authorization'] = "Bearer #{@access_token}"
        puts "Request Headers set: #{request.headers.inspect}"

        request_body = details_to_request_body.to_json
        puts "Request Body: #{JSON.pretty_generate(JSON.parse(request_body))}"
        request.body = request_body
      end

      puts "Response status: #{response.status}"
      puts "Response body: #{response.body}"
      response
    end

    def url_from_jwt
      ags_claim = @decoded_jwt["https://purl.imsglobal.org/spec/lti-ags/claim/endpoint"]
      puts "AGS claim from JWT: #{ags_claim.inspect}"

      if ags_claim.nil?
        puts "Warning: 'endpoint' claim not found in decoded JWT"
        return nil
      end

      line_item_url = ags_claim["lineitem"] + '/scores'
      if line_item_url.nil?
        puts "Warning: 'lineitem' key not found within 'endpoint' claim"
        return nil
      end

      puts "Line item URL: #{line_item_url}"
      line_item_url
    end

    def details_to_request_body
      @score_details || {
        timestamp: Time.now,
        scoreGiven: rand(1...100),
        scoreMaximum: 100,
        comment: 'Hmm this student needs to study',
        activityProgress: 'Completed',
        gradingProgress: 'FullyGraded',
        userId: @decoded_jwt['sub']
      }
    end
  end
end
