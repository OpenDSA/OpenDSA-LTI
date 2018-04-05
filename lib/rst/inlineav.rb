require_relative "directive"

class InlineAv < Directive
  attr_reader :threshold
  attr_reader :points
  attr_reader :output
  attr_reader :required
  attr_reader :links
  attr_reader :scripts

  def initialize(short_name, long_name, type, mod_name, links, scripts)
    super(short_name, long_name, type, mod_name)

    @links = links
    @scripts = scripts

    @points = 1
    @threshold = 1
    @required = true
    @output = 'show'
  end

  def embed_url(host)
    return "#{host}/embed/#{@short_name}"
  end

  def embed_code(host)
    url = "#{host}/embed/#{@short_name}"
    return "<iframe src=\"#{url}\" height=\"600\" width=\"100%\"></iframe>"
  end
end