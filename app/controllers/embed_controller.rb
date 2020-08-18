class EmbedController < ApplicationController
  after_action :allow_iframe, only: [:show, :index]

  # GET /embed
  # gives a list of embeddable slideshows and exercises
  # with links to the exercises and the html required to include
  # the resource in an iframe
  def index
    @folders = InstModule.get_embeddable_dict()
    @host_url = request.protocol + request.host_with_port
    @lti_launch_url = @host_url + "/lti/launch"
    render
  end

  # GET /embed/:ex_short_name
  # Displays an exercise
  def show
    @ex = InstExercise.find_by(short_name: params[:ex_short_name])
    if @ex.blank? || !@ex.learning_tool.blank?
      @message = "No resource found with the name \"#{params[:ex_short_name]}\""
      render 'lti/error' and return
    end
    if !@ex.av_address.blank?
      @ex_url = "#{request.protocol}#{request.host_with_port}/OpenDSA/#{@ex.av_address}"
      render 'embed_av', layout: 'embed_inlineav'
    elsif !@ex.learning_tool.blank?
      # external tool
      # not implemented
    else
      render 'embed_inlineav', layout: 'embed_inlineav'
    end
  end

  # GET /SourceCode/*
  # redirects to the static source code file
  def source_code_redirect
    redirect_to "#{request.protocol}#{request.host_with_port}/OpenDSA#{request.path}"
  end

  private

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end
end
