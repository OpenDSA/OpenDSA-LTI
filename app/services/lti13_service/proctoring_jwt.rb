# module for handling tool requests
module Lti13Service
  # Lti13Service::ProctoringJwt.new(launch).call
  class ProctoringJwt
    def initialize(launch)
      @launch = launch
      @tool = launch.tool
      @jwt = {}
    end

    def call
      @jwt[Rails.configuration.lti_claims_and_scopes['message_type']] = 'LtiStartAssessment'
      @jwt[Rails.configuration.lti_claims_and_scopes['lti_version']] = '1.3.0'
      @jwt[Rails.configuration.lti_claims_and_scopes['deployment_id']] = @tool.deployment_id
      add_security_details
      add_message_and_log
      add_proctoring_claims
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

    def add_message_and_log
      @jwt[Rails.configuration.lti_claims_and_scopes['deep_linking_tool_msg_claim']] = "Successfuly started proctoring session in Reference Implementation"
      @jwt[Rails.configuration.lti_claims_and_scopes['deep_linking_tool_log_claim']] = "Reference Implementation requested that platform start proctored assessment"
    end

    def add_proctoring_claims
      @jwt[Rails.configuration.lti_claims_and_scopes['attempt_number_claim']] = "1"

      data_claim = Rails.configuration.lti_claims_and_scopes['session_claim_data_claim']
      @jwt[data_claim] = @launch.decoded_jwt[data_claim]

      resource_link_claim = Rails.configuration.lti_claims_and_scopes['resource_link_claim']
      @jwt[resource_link_claim] = @launch.decoded_jwt[resource_link_claim]

      @jwt[Rails.configuration.lti_claims_and_scopes['proctoring_verified_user']] = {
        "given_name" => @launch.decoded_jwt['given_name'],
        "family_name" => @launch.decoded_jwt['family_name']
      }

      @jwt[Rails.configuration.lti_claims_and_scopes['launch_presentation']] = {
        "document_target" => "window",
        "return_url" => "https://proctor.org/stop",
        "locale" => "en-US"
      }
    end

    def create_signed_jwt
      Jwt::Encode.new(@jwt, @tool.openssl_private_key).call
    end
  end
end
