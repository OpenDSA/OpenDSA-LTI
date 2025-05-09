class LtiLaunchesController < ApplicationController
    def create
      # Clear expired launches for the same user and LMS instance
      LtiLaunch.where('expires_at < ?', Time.now)
              .where(lms_instance_id: params[:lms_instance_id], user_id: params[:user_id])
              .destroy_all

      # Create a new launch record
      @lti_launch = LtiLaunch.new(lti_launch_params)
      if @lti_launch.save
        render json: { message: 'LTI launch created successfully' }, status: :created
      else
        render json: { errors: @lti_launch.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    #~ Private instance methods .................................................
    private
  
    def lti_launch_params
      params.require(:lti_launch).permit(:lms_instance_id, :user_id, :course_offering_id, :id_token, :decoded_jwt, :kid, :expires_at)
    end
  end
  