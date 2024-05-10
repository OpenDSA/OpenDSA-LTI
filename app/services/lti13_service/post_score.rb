# module for handling platform requests
module Lti13Service
  # LtiPlatform::Keys.new(tool_objet).call
  class PostScore
    def initialize(access_token, decoded_jwt, score_details = nil)
      # puts "Decoded JWT from initialize: #{decoded_jwt}"
      @access_token = access_token
      puts "access_token from initialize: #{@access_token}"

      if decoded_jwt.is_a?(Array)
        @decoded_jwt = HashWithIndifferentAccess.new(decoded_jwt.first)
      else
        @decoded_jwt = decoded_jwt
        puts "Warning: Decoded JWT is not an array. Functionality might be impacted."
      end
      @score_details = score_details
      puts "Decoded JWT from initialize after hashing: #{@decoded_jwt}"
    end

    
    def call
      conn = Faraday.new(url: url_from_jwt)
      conn.post do |request|
        request.headers['Content-Type'] = 'application/vnd.ims.lis.v1.score+json'
        request.headers['Authorization'] = "Bearer #{@access_token}"
        puts "Request Headers:" # Print request body for debugging
        request.headers.each do |key, value|
          puts "  #{key}: #{value}"
        end
      
        request_body = details_to_request_body.to_json  # Generate request body
        puts "Request Body:"         # Print request body with proper indentation
        puts request_body.indent(2)
        request.body = request_body
      end
    end


    def url_from_jwt
      # Assuming the line item URL is within the 'endpoint' claim under 'ags_claim'
      ags_claim = @decoded_jwt["https://purl.imsglobal.org/spec/lti-ags/claim/endpoint"]
      puts "Decoded JWT ags  claim: #{ags_claim}"
      
      if ags_claim.nil?  # Check if 'endpoint' claim exists
        puts "Warning: 'endpoint' claim not found in decoded JWT"
        return nil  
      end
      
      line_item_url = ags_claim["lineitem"] + '/scores' # Extract the line item URL
      if line_item_url.nil?
        puts "Warning: 'lineitem' key not found within 'endpoint' claim"
        return nil  # Or handle the missing line item URL differently
      end
      puts "line item from Decoded JWT : #{line_item_url}"
      line_item_url   
    end
    
    # Todo: logic in here to map real score detail values, we will generate a random score
    def details_to_request_body
      # puts "Decoded JWT from post score: #{@decoded_jwt}" 
      return @score_details if @score_details
      {
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
