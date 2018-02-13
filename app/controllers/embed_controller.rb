class EmbedController < ApplicationController

    after_action :allow_iframe, only: [:show]

    # GET /embed
    # gives a list of embeddable slideshows and exercises
    # with links to the exercises and the html required to include
    # the resource in an iframe
    def index
        require 'RST/rst_parser'
        @folders = RstParser.get_exercise_info()
        @host_url = request.protocol + request.host_with_port
        render
    end

    # GET /embed/:ex_short_name
    # Displays an exercise
    def show
        require 'RST/rst_parser'
        @ex = RstParser.get_exercise_map()[params[:ex_short_name]]
        if @ex.blank?
            @message = "No resource found with the name \"#{params[:ex_short_name]}\""
            render 'lti/error' and return
        end
        if @ex.instance_of?(AvEmbed)
            redirect_to "#{request.protocol}#{request.host_with_port}#{@ex.av_address}"
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