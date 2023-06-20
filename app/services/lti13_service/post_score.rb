# module for handling platform requests
module Lti13Service
    # LtiPlatform::Keys.new(tool_objet).call
    class PostScore
      def initialize(access_token, decoded_jwt, score_details = nil)
        @access_token = access_token
        @decoded_jwt = HashWithIndifferentAccess.new(decoded_jwt)
        @score_details = score_details
      end
  
      def call
        conn = Faraday.new(url: url_from_jwt)
        conn.post do |request|
          request.headers['Content-Type'] = 'application/vnd.ims.lis.v1.score+json'
          request.headers['Authorization'] = "Bearer #{@access_token}"
          request.body = details_to_request_body.to_json
        end
      end
  
      def url_from_jwt
        @decoded_jwt[Rails.configuration.lti_claims_and_scopes['ags_claim']]['lineitem'] + '/scores'
      end
  
      # you would want logic in here to map real score detail values, we will generate a random score
      # @score_details will assume it was passed in as hash with correct keys
      def details_to_request_body
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