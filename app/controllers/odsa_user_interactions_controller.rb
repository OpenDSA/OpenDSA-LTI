class OdsaUserInteractionsController < ApplicationController
  # load_and_authorize_resource

  #~ Action methods ...........................................................

  def create
    @map = Map.new(map_params)
       respond_to do |format|
      if @map.save
        format.json {
          render :show, status: :created, location: @map
        }
      else
        format.json { render json: @map.errors, status: :unprocessable_entity }
      end
    end
  end

  # -------------------------------------------------------------
  # POST /odsa_user_interactions/create
  def create
    print params[:av]
    inst_book = InstBook.find_by(id: params[:inst_book_id])
    if params[:inst_section_id]
      inst_section = InstSection.find_by(id: params[:inst_section_id])
    end

    failed_to_save = false
    params[:eventList].each do |event|
      if event[:av] != ""
        inst_exercise = InstExercise.find_by(short_name: event[:av])
        print inst_exercise.id
        inst_book_section_exercise = InstBookSectionExercise.where(
                                                  "inst_book_id=? and inst_section_id=? and inst_exercise_id=?",
                                                    params[:inst_book_id], params[:inst_section_id], inst_exercise.id).first
      end
      # if browser.mobile?
      #   device = "Mobile"
      # elsif browser.tablet?
      #   device = "Tablet"
      # else
      #   device = "PC"
      # end
      @user_interaction = OdsaUserInteraction.new(
                                            inst_book: inst_book,
                                            user: current_user,
                                            inst_section: inst_section,
                                            inst_book_section_exercise: inst_book_section_exercise,
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
