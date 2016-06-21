class InstBooksController < ApplicationController
  load_and_authorize_resource

  #~ Action methods ...........................................................

  # -------------------------------------------------------------
  # POST /inst_books/upload_create
  def upload_create
    hash = JSON.load(File.read(params[:form][:file].path))
    InstBook.save_data_from_json(hash)


    redirect_to inst_books_url + '/upload', notice: 'Book configuration upload complete.'
  end

  # -------------------------------------------------------------
  # POST /inst_books/:id/compile
  def compile
    launch_url = request.protocol + request.host_with_port + "/lti/launch"
    @job = Delayed::Job.enqueue CompileBookJob.new(params[:id], launch_url, current_user.id)
  end

  #~ Private instance methods .................................................
end
