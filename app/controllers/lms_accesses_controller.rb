class LmsAccessesController < ApplicationController
# class InstBooksController < ApplicationController
  # load_and_authorize_resource


  #~ Action methods ...........................................................

  # -------------------------------------------------------------
  # POST /lms_accesses/:lms_instance_id/search
  def search
     puts  params['lms_instance_id']
     lms_accesses = LmsAccess.where("lms_instance_id = ? and user_id = ?", params['lms_instance_id'], current_user.id).first.as_json
     puts lms_accesses

     respond_to do |format|
          format.json {
              render json: lms_accesses
          }
    end
  end
  #~ Private instance methods .................................................
end
