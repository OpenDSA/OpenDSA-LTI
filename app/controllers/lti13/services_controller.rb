class Lti13::ServicesController < ApplicationController
    # POST /send_score?launch_id=1&access_token=ABC
    def send_score
      launch = Launch.find_by_id(params[:launch_id])
      response = Lti13Service::PostScore.new(params[:access_token], launch.decoded_jwt).call
  
      respond_to do |format|
        if (200..299).cover?(response.status)
          format.json { render json: JSON.parse(response.body), status: :ok }
        else
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