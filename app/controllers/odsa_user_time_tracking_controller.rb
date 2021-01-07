class OdsaUserTimeTrackingController < ApplicationController
  # load_and_authorize_resource

  #~ Action methods ...........................................................

  # -------------------------------------------------------------

  # POST /odsa_user_time_tracking/create
  def create
    failed_to_save = false
    errors = []
    # puts params[:modulesTracking]
    params[:modulesTracking].each_pair do |key, event|
      # puts event
      inst_book_id = event[:inst_book_id]
      inst_module_id = event[:inst_module_id]
      inst_chapter_id = event[:inst_chapter_id]

      @user_time_tracking = OdsaUserTimeTracking.new(
        user: current_user,
        inst_book_id: inst_book_id,
        inst_section_id: "",
        inst_book_section_exercise_id: "",
        inst_course_offering_exercise_id: "",
        inst_module_id: inst_module_id,
        inst_chapter_id: inst_chapter_id,
        inst_module_version_id: "",
        inst_module_section_exercise_id: "",
        uuid: event[:uuid],
        session_date: key.split('-')[2],
        total_time: event[:totalTime],
        sections_time: event[:sectionsTime]
      )
      if @user_time_tracking.save
        failed_to_save = false
      else
        failed_to_save = true
        error_msgs << @user_time_tracking.errors.full_messages
      end
    end

    respond_to do |format|
      if !failed_to_save
        msg = {:status => "ok", :message => "Success!"}
        status = :ok
      else
        msg = {:status => "fail", :message => "Fail!"}
        status = :bad_request
        error = Error.new(:class_name => 'user_interactions_save_fail',
                          :message => error_msgs.inspect, :params => params.to_s)
        error.save!
      end
      format.json { render :json => msg, :status => status }
    end
  end

  #~ Private instance methods .................................................
end
