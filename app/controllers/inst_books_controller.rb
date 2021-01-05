class InstBooksController < ApplicationController
  load_and_authorize_resource

  #~ Action methods ...........................................................

  # -------------------------------------------------------------
  # POST /inst_books/:id
  def compile
    host_port = request.protocol + request.host_with_port
    extrtool_launch_base_url = host_port + "/lti/launch_extrtool"
    if params[:operation] == 'generate_course'
      launch_url = host_port + "/lti/launch"
      resource_selection_url = host_port + "/lti/resource"
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
    inst_book = params['inst_book']

    script_path = "public/OpenDSA/tools/simple2full.py"

    input_file = sanitize_filename('temp_' + current_user.id.to_s + '_' + Time.now.getlocal.to_s) + '_input.json'
    input_file_path = "public/OpenDSA/config/temp/#{input_file}"
    File.open(input_file_path, 'w') { |file| file.write(inst_book.to_json) }

    output_file = sanitize_filename('temp_' + current_user.id.to_s + '_' + Time.now.getlocal.to_s) + '_full.json'
    output_file_path = "public/OpenDSA/config/temp/#{output_file}"
    require 'open3'
    command = ". $(echo $python_venv_path) && python3 #{script_path} #{input_file_path} #{output_file_path}"
    stdout, stderr, status = Open3.capture3(command)

    unless status.success?
      Rails.logger.info(stderr)
    end

    hash = JSON.load(File.read(output_file_path))

    InstBook.save_data_from_json(hash, current_user, inst_book['inst_book_id'])

    respond_to do |format|
      msg = {:status => "success", :message => "Book configuration uploaded successfully!"}
      format.json { render :json => msg }
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
