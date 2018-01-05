class InstBooksController < ApplicationController
  load_and_authorize_resource

  #~ Action methods ...........................................................

  # -------------------------------------------------------------
  # POST /inst_books/:id
  def compile
    if params[:operation] == 'generate_course'
      host_port = request.protocol + request.host_with_port
      launch_url = host_port + "/lti/launch"
      resource_selection_url = host_port + "/lti/resource"
      @job = Delayed::Job.enqueue GenerateCourseJob.new(params[:id], launch_url, resource_selection_url, current_user.id)
    else
      @job = Delayed::Job.enqueue CompileBookJob.new(params[:id], current_user.id)
    end
  end

  # -------------------------------------------------------------
  # POST /inst_books/configure/:id
  def configure
    @inst_book_json = ApplicationController.new.render_to_string(
        template: 'inst_books/show.json.jbuilder',
        locals: {:@inst_book => @inst_book})
  end

  # POST /inst_books/update
  def update
    inst_book = params['inst_book']
    byebug
    InstBook.save_data_from_json(inst_book, current_user, inst_book['inst_book_id'])

    respond_to do |format|
      msg = { :status => "success", :message => "Book configuration uploaded successfully!" }
      format.json  { render :json => msg }
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
end
