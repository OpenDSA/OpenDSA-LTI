class InstBooksController < ApplicationController
  load_and_authorize_resource

  #~ Action methods ...........................................................

  # -------------------------------------------------------------
  # POST /inst_books/:id
  def compile
    host_port = request.protocol + request.host_with_port
    extrtool_launch_base_url = host_port + "/lti/launch_extrtool"
    inst_book = InstBook.find(params[:id])
    course_offering = inst_book.course_offering
    lms_instance = course_offering.lms_instance

    # Determine LTI version from the LmsInstance
    lti_version = lms_instance.lti_version
    puts "Determined LTI version: #{lti_version}"
    # Set URLs based on the LTI version
    if params[:operation] == 'generate_course'
      if lti_version == 'LTI-1p0'
        launch_url = host_port + "/lti/launch"
        resource_selection_url = host_port + "/lti/resource"
      elsif lti_version == 'LTI-1p3'
        launch_url = host_port + "/lti13/launches"
        resource_selection_url = host_port + "/lti13/deep_linking/content_selection"
      else
        render plain: "Unsupported LTI version", status: :unprocessable_entity
        return
      end
      @job = Delayed::Job.enqueue GenerateCourseJob.new(params[:id], launch_url, resource_selection_url,
                                                        extrtool_launch_base_url, current_user.id)
    else
      @job = Delayed::Job.enqueue CompileBookJob.new(params[:id], extrtool_launch_base_url, current_user.id)
    end
  end

  # -------------------------------------------------------------
  # POST /inst_books/configure/:id
  def configure
    @inst_book_json = ApplicationController.new.render_to_string(
      template: 'inst_books/show.json.jbuilder',
      locals: {:@inst_book => @inst_book},
    )
  end

  def validate_configuration
    book = InstBook.find(params[:id])
    if (book.blank?)
      render json: {status: "fail", message: "Book not found."}, status: :not_found
    end
    errors = book.validate_configuration()
    render json: {status: "success", res: errors}
  end

  # POST /inst_books/update
  def update
    if params['deadlines']
      inst_book = params['inst_book']
      chapters = inst_book['chapters']
      chapters.each do |key, modules|
        ch = InstChapter.where("inst_book_id = ? AND name = ?", inst_book['inst_book_id'], key).first
        module_pos = 1
        modules.each do |name, deadline|
          due_date = nil
          if (deadline != "undefined") 
            due_date = Time.strptime(deadline, "%m/%d/%Y %I:%M %P").strftime("%Y-%m-%d %H:%M")
          end
          md = InstModule.where("name = ?", name).first
          inst_chap_module = InstChapterModule.where("inst_chapter_id = ? AND module_position = ?", ch.id, module_pos).first
          inst_chap_module.update(due_dates: due_date)
          module_pos = module_pos + 1
        end
      end
      
      respond_to do |format|
        msg = {:status => "success", :message => "Modules due dates has been set successfully!"}
        format.json { render :json => msg }
      end

    else
      inst_book = params['inst_book']

      input_file = sanitize_filename('temp_' + current_user.id.to_s + '_' + Time.now.getlocal.to_s) + '_input.json'
      input_file_path = "public/OpenDSA/config/temp/#{input_file}"
      Rails.logger.info(inst_book.to_json);
      File.open(input_file_path, 'w') { |file| file.write(inst_book.to_json) }
      input_path = input_file_path[15..-1] # without the public/OpenDSA

      output_file = sanitize_filename('temp_' + current_user.id.to_s + '_' + Time.now.getlocal.to_s) + '_full.json'
      output_file_path = "public/OpenDSA/config/temp/#{output_file}"
      File.open(output_file_path, 'w') { |file| file.write(inst_book.to_json) }
      output_path = output_file_path[15..-1] # without the public/OpenDSA
      require 'net/http'
      uri = URI(ENV["simple_api_link"])
      res = Net::HTTP.post_form(uri, 'input_path' => input_path, 'output_path' => output_path, 'rake' => false)
      unless res.kind_of? Net::HTTPSuccess
        Rails.logger.info(res['stderr_compressed'])
      end

      hash = JSON.load(File.read(output_file_path))

      InstBook.save_data_from_json(hash, current_user, inst_book['inst_book_id'])

      respond_to do |format|
        msg = {:status => "success", :message => "Book configuration uploaded successfully!"}
        format.json { render :json => msg }
      end
    end
  end

  def configuration
    @inst_book = InstBook.find_by(id: params[:id])
    render :json => @inst_book.to_builder.target!
    #render :json => ApplicationController.new.render_to_string(
    #  template: 'inst_books/show.json.jbuilder',
    #  locals: {:@inst_book => @inst_book})
  end

  #~ Private instance methods .................................................
  private

  def sanitize_filename(filename)
    filename.gsub(/[^\w\s_-]+/, '')
      .gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2')
      .gsub(/\s+/, '_')
  end
end
