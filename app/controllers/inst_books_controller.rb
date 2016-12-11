class InstBooksController < ApplicationController
  load_and_authorize_resource

  #~ Action methods ...........................................................

  # -------------------------------------------------------------
  # POST /inst_books/:id
  def compile
    if params[:operation] == 'generate_course'
      launch_url = request.protocol + request.host_with_port + "/lti/launch"
      @job = Delayed::Job.enqueue GenerateCourseJob.new(params[:id], launch_url, current_user.id)
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

  # POST /inst_books/update/:id
  def update
    # @inst_book_json = ApplicationController.new.render_to_string(
    #     template: 'inst_books/show.json.jbuilder',
    #     locals: {:@inst_book => @inst_book})
    inst_book = params['inst_book']

    # InstBook.save_data_from_json(inst_book, current_user)

    redirect_to book_configure_path(:id => inst_book['id']), notice: 'Book configuration uploaded successfully!'

  end

  #~ Private instance methods .................................................
end
