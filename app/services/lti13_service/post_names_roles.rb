module Lti13Service
  # Handles retrieval of names and roles from the LTI 1.3 Names and Roles Provisioning Service (NRPS).
  # Makes an HTTP GET request to the platform's NRPS endpoint to fetch the membership container.(lms course)
  
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
        Rails.logger.info "Request Headers:"
        request.headers.each { |key, value| puts "  #{key}: #{value}" }
      end

       # Log the response status and body for debugging
       Rails.logger.info "Response status: #{response.status}"
       Rails.logger.info "Response body from post names role: #{response.body}"
      response
    end

    #~ Private methods ..........................................................
    private
   
    def url_from_jwt
      names_roles_claim = @decoded_jwt["https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice"]
      Rails.logger.info "Decoded JWT names_roles_claim: #{names_roles_claim}"
      
      if names_roles_claim.nil?
        Rails.logger.warn  "Warning: 'namesroleservice' claim not found in decoded JWT"
        return nil
      end

      names_roles_url = names_roles_claim["context_memberships_url"]
      if names_roles_url.nil?
        Rails.logger.warn "Warning: 'context_memberships_url' key not found within 'namesroleservice' claim"
        return nil
      end
      Rails.logger.info "Names and roles URL from Decoded JWT: #{names_roles_url}"
      names_roles_url
    end
  end
end