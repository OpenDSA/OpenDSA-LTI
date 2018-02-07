class Directive
  attr_reader :short_name
  attr_reader :long_name
  attr_reader :type
  attr_accessor :id
  attr_reader :mod_name

  def initialize(short_name, long_name, type, mod_name)
    @short_name = short_name
    @long_name = long_name
    @type = type
    @mod_name = mod_name
  end

  def to_json(arg)
    return %{"short_name": "#{@short_name}","long_name": "#{@long_name}"}
  end
end