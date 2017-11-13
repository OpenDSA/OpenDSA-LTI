class OdsaUserInteractionsController < ApplicationController
  # load_and_authorize_resource

  #~ Action methods ...........................................................

  # -------------------------------------------------------------
  # POST /odsa_user_interactions/create
  def create
    failed_to_save = false
    params[:eventList].each do |event|
      hasBook = event.key?(:inst_book_id)
      if hasBook
        inst_course_offering_exercise_id = nil
        inst_book_id = params[:inst_book_id]
        if event[:inst_section_id] !=""
          inst_section_id = event[:inst_section_id]
        end
        if event[:av] != ""
          inst_exercise = InstExercise.find_by(short_name: event[:av])
          inst_book_section_exercise = InstBookSectionExercise.where(
                                      "inst_book_id=? and inst_section_id=? and inst_exercise_id=?",
                                        inst_book_id, inst_section_id, inst_exercise.id).first
        end
      else
        inst_course_offering_exercise_id = event[:inst_course_offering_exercise_id]
        inst_book_id = nil
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
                                            inst_book_section_exercise: inst_book_section_exercise,
                                            inst_course_offering_exercise_id: inst_course_offering_exercise_id,
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
                                            ip_address: request.ip)
      if @user_interaction.save
        failed_to_save = false
      else
        failed_to_save = true
      end
    end

    respond_to do |format|
      if !failed_to_save
        msg = { :status => "ok", :message => "Success!" }
      else
        msg = { :status => "fail", :message => "Fail!" }
      end
      format.json  { render :json => msg }
    end
  end

  #~ Private instance methods .................................................
end
