module Lti13Service
  class PostNamesRoles
    def initialize(access_token, decoded_jwt)
      @access_token = access_token
      @decoded_jwt = decoded_jwt.is_a?(Array) ? HashWithIndifferentAccess.new(decoded_jwt.first) : decoded_jwt
    end

    def call
      conn = Faraday.new(url: url_from_jwt)
      response = conn.get do |request|
        request.headers['Content-Type'] = 'application/json'
        request.headers['Authorization'] = "Bearer #{@access_token}"
        request.headers['Accept'] = 'application/vnd.ims.lti-nrps.v2.membershipcontainer+json'
        puts "Request Headers:"
        request.headers.each { |key, value| puts "  #{key}: #{value}" }
      end

      puts "Response status: #{response.status}"
      puts "Response body from post names role: #{response.body}"
      response
    end

    private

    def url_from_jwt
      names_roles_claim = @decoded_jwt["https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice"]
      puts "Decoded JWT names_roles_claim: #{names_roles_claim}"
      
      if names_roles_claim.nil?
        puts "Warning: 'namesroleservice' claim not found in decoded JWT"
        return nil
      end

      names_roles_url = names_roles_claim["context_memberships_url"]
      if names_roles_url.nil?
        puts "Warning: 'context_memberships_url' key not found within 'namesroleservice' claim"
        return nil
      end
      puts "Names and roles URL from Decoded JWT: #{names_roles_url}"
      names_roles_url
    end
  end
end