module Lti13Service
  # Lti13Service::ProctoringJwt.new(launch, lms_instance).call
  class ProctoringJwt
    def initialize(launch, lms_instance)
      @launch = launch
      @lms_instance = lms_instance
      @launch_payload = launch_payload
      @jwt = {}
    end

    def call
      @jwt[Rails.configuration.lti_claims_and_scopes['message_type']] = 'LtiStartAssessment'
      @jwt[Rails.configuration.lti_claims_and_scopes['lti_version']] = '1.3.0'
      @jwt[Rails.configuration.lti_claims_and_scopes['deployment_id']] = deployment_id
      add_security_details
      add_message_and_log
      add_proctoring_claims
      create_signed_jwt
    end

    def add_security_details
      @jwt['iss'] = @lms_instance.client_id
      @jwt['aud'] = @launch_payload['iss']
      @jwt['iat'] = Time.now.to_i
      @jwt['exp'] = Time.now.to_i + 300
      @jwt['nonce'] = SecureRandom.hex(10)
    end

    def add_message_and_log
      @jwt[Rails.configuration.lti_claims_and_scopes['deep_linking_tool_msg_claim']] = "Successfully started proctoring session in OpenDSA"
      @jwt[Rails.configuration.lti_claims_and_scopes['deep_linking_tool_log_claim']] = "OpenDSA requested that platform start proctored assessment"
    end

    def add_proctoring_claims
      @jwt[Rails.configuration.lti_claims_and_scopes['attempt_number_claim']] = "1"

      data_claim = Rails.configuration.lti_claims_and_scopes['session_claim_data_claim']
      @jwt[data_claim] = @launch_payload[data_claim]

      resource_link_claim = Rails.configuration.lti_claims_and_scopes['resource_link_claim']
      @jwt[resource_link_claim] = @launch_payload[resource_link_claim]

      @jwt[Rails.configuration.lti_claims_and_scopes['proctoring_verified_user']] = {
        "given_name" => @launch_payload['given_name'],
        "family_name" => @launch_payload['family_name']
      }

      @jwt[Rails.configuration.lti_claims_and_scopes['launch_presentation']] = {
        "document_target" => "window",
        "return_url" => "https://proctor.org/stop",
        "locale" => "en-US"
      }
    end

    def create_signed_jwt
      Jwt::Encode.new(@jwt, @lms_instance.openssl_private_key).call
    end

    private

    def launch_payload
      dj = @launch.decoded_jwt
      dj.is_a?(Array) ? dj.first : dj
    end

    def deployment_id
      @launch_payload[Rails.configuration.lti_claims_and_scopes['deployment_id']]
    end
  end
end
