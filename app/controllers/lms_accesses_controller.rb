class LmsAccessesController < ApplicationController
# class InstBooksController < ApplicationController
  # load_and_authorize_resource


  #~ Action methods ...........................................................

  # -------------------------------------------------------------
  # POST /lms_accesses/:lms_instance_id/search
  def search
    lms_access = LmsAccess.where("lms_instance_id = ? and user_id = ?", params['lms_instance_id'], current_user.id).first.as_json
    lms_instance = LmsInstance.where("id = ?", params['lms_instance_id']).first

    valid_token = false
    if lms_access and lms_access['access_token']
      require 'pandarus'
      client = Pandarus::Client.new(
        prefix: lms_instance.url + '/api',
        token: lms_access['access_token'])
      remote_collection = client.list_your_courses()

      begin
        courses = remote_collection.first_page
        valid_token = true
      rescue => ex
        if ex.class == 'Footrest::HttpError::Unauthorized'
          valid_token = false
        end
      end
    end

    if !lms_access
      lms_access = {}
    end

    lms_access['valid_token'] = valid_token

    respond_to do |format|
        format.json {
            render json: lms_access
        }
    end
  end
  #~ Private instance methods .................................................
end
