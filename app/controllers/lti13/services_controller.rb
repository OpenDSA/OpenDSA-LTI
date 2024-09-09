class Lti13::ServicesController < ApplicationController
  # skip_before_action :verify_authenticity_token

  # Handles the POST request to submit scores to the LMS.
  # POST /send_score?launch_id=1&access_token=ABC&platform_jwt=xx&kid=xxx&highest_score
  def send_score(launch_id:, access_token:, platform_jwt:, kid:, highest_score:)
    Rails.logger.info "Starting send_score method"
    # puts "Launch ID: #{launch_id}, Access Token: #{access_token}, Highest Score: #{highest_score}"
    lms_instance = LmsInstance.find_by_id(launch_id)
    unless lms_instance
      return { error: 'LMS Instance not found', status: :not_found }
    end
    if access_token.nil?
      access_token_response = Lti13Service::GetAgsAccessToken.new(lms_instance).call
      if access_token_response.is_a?(Hash) && access_token_response['access_token'].present?
        access_token = access_token_response['access_token']
      else
        Rails.logger.info "Failed to retrieve access token"
        return { error: 'Failed to retrieve access token', status: :internal_server_error }
      end
    end
    decoded_jwt = Lti13Service::DecodePlatformJwt.new(lms_instance, platform_jwt, kid).call
    Rails.logger.info "Attempting to post score..."
    response = Lti13Service::PostScore.new(access_token, decoded_jwt, highest_score: highest_score).call
  
    if response.nil?
      return { error: 'Response is nil', status: :internal_server_error }
    end
    Rails.logger.info "Response status: #{response.status}"
  
    if response.status == 204
      Rails.logger.info "Score submission successful"
      { message: "Score submission successful", status: :ok }
    elsif (200..299).cover?(response.status)
      Rails.logger.info "Score submission successful with response: #{response.body}"
      { body: JSON.parse(response.body), status: :ok }
    else
      Rails.logger.info "** Error submitting score! Response status: #{response.status}, Response body: #{response.body}"
      { body: JSON.parse(response.body), status: :unprocessable_entity }
    end  
  rescue => e
    Rails.logger.info "Error in servicesController#send_score: #{e.message}"
    { error: e.message, status: :internal_server_error }
  end
  
  

  # Handles POST request to fetch names and roles from LMS.
  # POST /request_names_and_roles?launch_id=1&access_token=ABC
  def request_names_and_roles(launch_id:, access_token:, platform_jwt:, kid:)
    lms_instance = LmsInstance.find_by_id(launch_id)
    unless lms_instance
      render json: { error: 'LMS Instance not found' }, status: :not_found
      return
    end
    # If access_token is not provided, retrieve using the Lti13Service::GetAgsAccessToken service
    if access_token.nil?
      access_token_response = Lti13Service::GetAgsAccessToken.new(lms_instance).call
      if access_token_response.is_a?(Hash) && access_token_response['access_token'].present?
        access_token = access_token_response['access_token']
      else
        render json: { error: 'Failed to retrieve access token' }, status: :internal_server_error
        return
      end
    end
    decoded_jwt = Lti13Service::DecodePlatformJwt.new(lms_instance, platform_jwt, kid).call    
    response = Lti13Service::PostNamesRoles.new(access_token, decoded_jwt).call
    if response.nil?
      render json: { error: 'Response is nil' }, status: :internal_server_error
      return
    end
    if response.status == 204
      { message: "Names and roles request successful", status: :ok }
    elsif (200..299).cover?(response.status)
      { message: "Names and roles request successful", body: JSON.parse(response.body), status: :ok }
    else
      { error: response.body, status: response.status }
    end
  rescue => e
    Rails.logger.info "Error in servicesController#request_names_and_roles: #{e.message}"
    { error: e.message, status: :internal_server_error }
  end
   
end