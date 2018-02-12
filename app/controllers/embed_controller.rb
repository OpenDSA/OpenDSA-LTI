class EmbedController < ApplicationController

    after_action :allow_iframe, only: [:show]

    def index
        require 'RST/rst_parser'
        @folders = RstParser.get_exercise_info()
        @host_url = request.protocol + request.host_with_port
        render
    end

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

    private

    def allow_iframe
        response.headers.except! 'X-Frame-Options'
    end

end