# module for handling platform requests
module Lti13Service
  # Lti13Service::DeepLinkJwt.new(tool_objet).call
  class DeepLinkJwt
    attr_accessor :jwt, :signed_jwt

    def initialize(launch, tool_launch_url, content_items = [])
      @launch = launch
      @tool = launch.tool
      @tool_launch_url = tool_launch_url
      @content_items = content_items
      @jwt = {}
      generate_jwt
    end

    def generate_jwt
      @jwt[Rails.configuration.lti_claims_and_scopes['message_type']] = 'LtiDeepLinkingResponse'
      @jwt[Rails.configuration.lti_claims_and_scopes['lti_version']] = '1.3.0'
      @jwt[Rails.configuration.lti_claims_and_scopes['deployment_id']] = @tool.deployment_id
      add_security_details
      add_content_items
      add_data_claim
      add_message_and_log
      create_signed_jwt
    end

    def add_security_details
      # iss is is the tool identifier from the platform standpoint
      @jwt['iss'] = @tool.client_id

      # Audience(s) for whom this ID Token is intended i.e. the platform iss from id_token recieved during initial message to tool from platform
      @jwt['aud'] = @launch.decoded_jwt['iss']

      # Time at which the Issuer generated the JWT (epoch)
      @jwt['iat'] = Time.now.to_i

      # Expiration time on or after which the Client MUST NOT accept the ID Token for processing (epoch)
      # reference implementation provides 5 minutes for clock skew
      @jwt['exp'] = Time.now.to_i + 300

      # No sub for the a message back to the platform
      # @launch_data['sub'] = 'n/a'

      # String value used to associate a Client session with an ID Token, and to mitigate replay attacks. The nonce value is a case-sensitive string.
      @jwt['nonce'] = SecureRandom.hex(10)
    end

    def add_content_items
      content = []
      content << @tool.html_item if @content_items.include?('html_item')
      content << @tool.link_item if @content_items.include?('html_link')
      content << @tool.image_item if @content_items.include?('image_item')
      content << @tool.lti_item(@tool_launch_url) if @content_items.include?('lti_link')
      content << @tool.file_item if @content_items.include?('file_link')
      @jwt[Rails.configuration.lti_claims_and_scopes['content_item_claim']] = content
    end

    def add_data_claim
      data = @launch.decoded_jwt[Rails.configuration.lti_claims_and_scopes['deep_linking_claim']]['data']
      @jwt[Rails.configuration.lti_claims_and_scopes['deep_linking_data_claim']] = data if data
    end

    def add_message_and_log
      @jwt[Rails.configuration.lti_claims_and_scopes['deep_linking_tool_msg_claim']] = "Successfuly added #{@content_items.count} Content Items from Reference Implementation"
      @jwt[Rails.configuration.lti_claims_and_scopes['deep_linking_tool_log_claim']] = "Reference Implementation requested that the following type of content items be added: #{@content_items.to_s}"
    end

    def create_signed_jwt
      @signed_jwt = Jwt::Encode.new(@jwt, @tool.openssl_private_key).call
    end
  end
end
