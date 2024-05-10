class Lti13::ServicesController < ApplicationController
    # skip_before_action :verify_authenticity_token
    # POST /send_score?launch_id=1&access_token=ABC
    def send_score(launch_id:, access_token:, platform_jwt:, kid:)
      
      lms_instance = LmsInstance.find_by_id(launch_id) # Find the LMS instance using the launch_id parameter
  
      unless lms_instance # Ensuring LMS instance is found
        render json: { error: 'LMS Instance not found' }, status: :not_found
        return
      end
    
      puts "servicesController#create platform_jwt: Decoded JWT: #{platform_jwt}" # debug statements for test (to be moved to test)
      puts "servicesController#create platform_jwt: access code: #{access_token}"
      decoded_jwt = Lti13Service::DecodePlatformJwt.new(lms_instance, platform_jwt, kid).call # Decode the JWT using the DecodePlatformJwt service class
      puts "servicesController#create: Decoded JWT: #{decoded_jwt}"
    
      # Check if the JWT was decoded successfully
      if decoded_jwt.nil?
        puts "Failed to decode JWT. Aborting send_score."
        return
      end    
      response = Lti13Service::PostScore.new(access_token, decoded_jwt).call  # Call the PostScore service with the provided access_token and decoded_jwt
      puts "printing response from service controller  #{response}"
      
      # Respond based on the response status
      respond_to do |format|
        if (200..299).cover?(response.status)
          puts "** Successful score submission! Response status: #{response.status}"
          format.json { render json: JSON.parse(response.body), status: :ok }
        else
          puts "** Error submitting score! Response status: #{response.status}"
          puts "** Response body: #{response.body}"  # Print the full response body
          format.json { render json: JSON.parse(response.body), status: :unprocessable_entity }
        end
      end
    end
    
    # POST /request_names_and_roles?launch_id=1&access_token=ABC
    def request_names_and_roles
      launch = Launch.find_by_id(params[:launch_id])
      response = Lti13Service::PostNamesRoles.new(params[:access_token], launch.decoded_jwt).call
  
      respond_to do |format|
        if (200..299).cover?(response.status)
          format.json { render json: JSON.parse(response.body), status: :ok }
        else
          format.json { render json: JSON.parse(response.body), status: :unprocessable_entity }
        end
      end
    end
  end