class OdsaUserInteractionsController < ApplicationController
  # load_and_authorize_resource

  #~ Action methods ...........................................................

  # -------------------------------------------------------------
  # POST /odsa_user_interactions/create
  def create
    failed_to_save = false
    errors = []
    params[:eventList].each do |event|
      hasBook = event.key?(:inst_book_id)
      is_standalone_module = event.key?(:inst_module_version_id)
      
      if hasBook
        inst_book_id = params[:inst_book_id]
        if event[:inst_section_id] != ""
          inst_section_id = event[:inst_section_id]
        end
        if event[:inst_chapter_module_id] != ""
          inst_chapter_module_id = event[:inst_chapter_module_id]
        end
        if event.key?(:inst_book_section_exercise_id)
          inst_book_section_exercise_id = event[:inst_book_section_exercise_id]
        elsif event[:av] != ""
          inst_exercise = InstExercise.find_by(short_name: event[:av])
          inst_book_section_exercise_id = InstBookSectionExercise.where(
            "inst_book_id=? and inst_section_id=? and inst_exercise_id=?",
            inst_book_id, inst_section_id, inst_exercise.id
          ).pluck(:id).first
        end
      elsif is_standalone_module
        inst_module_version_id = event[:inst_module_version_id]
        if event[:inst_module_section_exercise_id] != ""
          inst_module_section_exercise_id = event[:inst_module_section_exercise_id]
        end
      else
        inst_course_offering_exercise_id = event[:inst_course_offering_exercise_id]
      end

      # if browser.mobile?
      #   device = "Mobile"
      # elsif browser.tablet?
      #   device = "Tablet"
      # else
      #   device = "PC"
      # end
      @user_interaction = OdsaUserInteraction.new(
        inst_book_id: inst_book_id,
        user: current_user,
        inst_section_id: inst_section_id,
        inst_chapter_module_id: inst_chapter_module_id,
        inst_book_section_exercise_id: inst_book_section_exercise_id,
        inst_course_offering_exercise_id: inst_course_offering_exercise_id,
        inst_module_version_id: inst_module_version_id,
        inst_module_section_exercise_id: inst_module_section_exercise_id,
        name: event[:type],
        description: event[:desc],
        action_time: Time.at(event[:tstamp].to_f / 1000),
        uiid: event[:uiid],
        browser_family: browser.name,
        browser_version: browser.version,
        os_family: browser.platform.to_s,
        os_version: "",
        # device: device,
        device: "PC",
        ip_address: request.ip,
      )
      if @user_interaction.save
        failed_to_save = false
      else
        failed_to_save = true
        error_msgs << @user_interaction.errors.full_messages
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
