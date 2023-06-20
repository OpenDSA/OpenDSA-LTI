# module for handling platform requests
module Lti13Service
    # LtiPlatform::Keys.new(tool_objet).call
    class PostNamesRoles
      def initialize(access_token, decoded_jwt)
        @access_token = access_token
        @decoded_jwt = HashWithIndifferentAccess.new(decoded_jwt)
      end
  
      def call
        conn = Faraday.new(url: url_from_jwt)
        conn.get do |request|
          request.headers['Accept'] = 'application/vnd.ims.lti-nrps.v2.membershipcontainer+json'
          request.headers['Authorization'] = "Bearer #{@access_token}"
        end
      end
  
      # limit query param - see 'Limit query parameter' section of NRPS spec
      # to get differences - see 'Membership differences' section of NRPS spec
      # query parameter of 'role=http%3A%2%2Fpurl.imsglobal.org%2Fvocab%2Flis%2Fv2%2Fmembership%23Learner' will filter the memberships to just those which have a Learner role.
      # query parameter of 'rlid=49566-rkk96' will filter the memberships to just those which have access to the resource link with ID '49566-rkk96'
      def url_from_jwt
        @decoded_jwt[Rails.configuration.lti_claims_and_scopes['names_and_roles_claim']]['context_memberships_url']
      end
    end
  end