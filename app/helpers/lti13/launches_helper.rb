module Lti13::LaunchesHelper
  def security_code_block(jwt_body)
    jwt_body = jwt_body.first if jwt_body.is_a?(Array)
    return {} unless jwt_body
    jwt_body.slice('iss', 'sub', 'aud', 'exp', 'iat', 'azp', 'nonce')
  end

  def claims_code_block(jwt_body)
    jwt_body = jwt_body.first if jwt_body.is_a?(Array)
    return {} unless jwt_body
    jwt_body.select { |key, _value| key.to_s.match(/imsglobal.org/) }
  end

  def non_claim_security_code_block(jwt_body)
    jwt_body = jwt_body.first if jwt_body.is_a?(Array)
    return {} unless jwt_body
    viewed_keys = security_code_block(jwt_body).keys + claims_code_block(jwt_body).keys
    jwt_body.select { |key, _value| viewed_keys.flatten.exclude?(key) }
  end

  def deep_link_launch?(jwt_body)
    jwt_body = jwt_body.first if jwt_body.is_a?(Array)
    return false unless jwt_body
    jwt_body[Rails.configuration.lti_claims_and_scopes['message_type']] == 'LtiDeepLinkingRequest'
  end

  def names_and_roles_launch?(jwt_body)
    jwt_body = jwt_body.first if jwt_body.is_a?(Array)
    return false unless jwt_body

    names_and_roles_claim_key = Rails.configuration.lti_claims_and_scopes['names_and_roles_claim']
    return false unless jwt_body[names_and_roles_claim_key]

    version = Rails.configuration.lti_claims_and_scopes['names_and_roles_service_versions']
    jwt_body[names_and_roles_claim_key]['service_versions'] == version
  end

  def proctoring_launch?(jwt_body)
    jwt_body = jwt_body.first if jwt_body.is_a?(Array)
    return false unless jwt_body
    jwt_body[Rails.configuration.lti_claims_and_scopes['message_type']] == 'LtiStartProctoring'
  end

  def proctoring_url(jwt_body)
    jwt_body = jwt_body.first if jwt_body.is_a?(Array)
    return nil unless jwt_body
    jwt_body[Rails.configuration.lti_claims_and_scopes['start_assessment_url_claim']]
  end

  def proctoring_jwt(launch)
    LtiService::ProctoringJwt.new(launch).call
  end

  def assignment_and_grades_launch?(jwt_body)
    jwt_body = jwt_body.first if jwt_body.is_a?(Array)
    ags_claim_key = Rails.configuration.lti_claims_and_scopes['ags_claim']
    puts "AGS Claim Key: #{ags_claim_key.inspect}"
    puts "JWT Body: #{jwt_body.inspect}"
    jwt_body && ags_claim_key && jwt_body[ags_claim_key]
  end
end