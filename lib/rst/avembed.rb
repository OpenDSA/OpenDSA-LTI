require_relative "directive"

class AvEmbed < Directive
  attr_reader :width
  attr_reader :height
  attr_reader :showhide
  attr_reader :required
  attr_reader :threshold
  attr_reader :points
  attr_reader :external
  attr_reader :av_address

  def initialize(short_name, long_name, type, mod_name, av_address, width = 950, height = 650)
    super(short_name, long_name, type, mod_name)
    @av_address = av_address
    @width = width
    @height = height
    @showhide = 'show'
    @required = true

    @points = 1
    if type == 'ka'
      @threshold = 5
    else
      @threshold = 1
    end
  end

  def embed_url(host)
    #return "#{host}#{@av_address}"
    return "#{host}/embed/#{@short_name}"
  end

  def embed_code(host)
    return "<iframe src=\"#{embed_url(host)}\" height=\"#{@height}\" width=\"100%\" scrolling=\"no\"></iframe>"
  end
end
