require 'json'

# Helper classes
class RSTtoJSON
  def self.convert(path, lang)
    json = {} # The json for this directory
    json["children"] = []
    json["type"] = "chapter"
    json["path"] = path
    json["text"] = File.basename(path)
    json["id"] = json["text"].downcase
    Dir.foreach(path) do |entry|
      child = {}
      if entry == '.' or entry == '..'
        # Skip over the current and parent directory
        next
      end
      # Concatenate the subpath with the entry and path
      subpath = File.join(path, entry)
      if File.file?(subpath) and File.extname(subpath) == '.rst'
        # found a module rst file
        mod_info = self.extract_module_info(subpath, lang)
        mod_info[:parent_id] = json["id"].blank? ? '#' : json["id"]
        json["children"].push(mod_info)
      elsif Dir.exists?(subpath)
        # must be a directory so convert the subpath
        child = self.convert(subpath, lang)
        json["children"].push(child)
      end
    end
    return json
  end

  private

  # use ||= to avoid "already intialized constant" warning
  # since rails will reload the class on every request during development

  # regex to identify section titles
  SECTION_RE ||= Regexp.new('^-+$')
  URI_ESCAPE_RE ||= Regexp.new("[^#{URI::PATTERN::UNRESERVED}']")
  URI_REMOVE_RE ||= /[%'()]/

  def self.extract_module_info(rst_path, lang)
    lines = File.readlines(rst_path)
    i = 0
    mod_lname = ""
    mod_sname = File.basename(rst_path, '.rst')
    mod_path = rst_path.sub("public/OpenDSA/RST/#{lang}/", '').sub('.rst', '')
    mod = {
      # escape the id so it can be used as an HTML element id
      id: URI.escape(mod_path, URI_ESCAPE_RE).gsub(URI_REMOVE_RE, '').downcase!,
      path: mod_path,
      short_name: mod_sname,
      children: [],
      type: 'module',
    }

    # find the module title
    while i < lines.count
      line = lines[i]
      sline = line.strip()
      if sline.start_with?("==") and not lines[i - 1].strip().empty?
        mod_lname = lines[i - 1].strip()
        i += 1
        break
      end
      i += 1
    end

    if mod_lname == ""
      mod_lname = mod_sname
      i = 0
    end

    mod[:long_name] = mod_lname
    mod[:text] = "#{mod_lname} (#{mod_path})"

    curr_section = mod
    # extract info about the sections and exercises that are in the module
    while i < lines.count
      line = lines[i]
      sline = line.strip()

      if sline == ""
        i += 1
        next
      end

      if SECTION_RE.match(sline) != nil
        sectName = lines[i - 1].strip()
        curr_section = {
          text: sectName,
          children: [], # exercises
          type: 'section',
          id: URI.escape("#{mod_path}|sect|#{sectName}", URI_ESCAPE_RE).gsub(URI_REMOVE_RE, '').downcase!,
        }
        mod[:children] << curr_section
        i += 1
        next
      end

      match_data = OpenDSA::EXERCISE_RE.match(sline)
      if match_data != nil
        # found an exercise or slideshow
        directive = match_data[2]
        identifier = match_data[3]
        ex_type = match_data[7]
        ex_sname = match_data[5]
        ex_lname = ""

        i += 1
        i, options = parse_directive_options(i, lines)

        if options.has_key?('long_name')
          ex_lname = options.delete('long_name')
        else
          ex_lname = ex_sname
        end

        ex_text = ex_lname == ex_sname ? ex_lname : "#{ex_lname} (#{ex_sname})"
        curr_section[:children] << {
          short_name: ex_sname,
          long_name: ex_lname,
          text: ex_text,
          type: ex_type,
          id: URI.escape("#{mod_path}||#{ex_sname}", URI_ESCAPE_RE).gsub(URI_REMOVE_RE, '').downcase!,
        }
      else
        match_data = OpenDSA::EXTR_RE.match(sline)
        if match_data != nil
          # found an external tool exercise

          ex_name = match_data[3]

          i += 1
          i, options = parse_directive_options(i, lines)

          learning_tool = options.fetch('learning_tool', 'code-workout')

          curr_section[:children] << {
            short_name: ex_name,
            long_name: ex_name,
            learning_tool: learning_tool,
            text: "#{ex_name} (#{learning_tool})",
            type: 'extr',
            id: URI.escape("#{mod_path}||#{ex_name}", URI_ESCAPE_RE).gsub(URI_REMOVE_RE, '').downcase!,
          }
        else
          i += 1
        end
      end
    end
    return mod
  end

  # parse the options for the directive that starts on line i
  # returning the first line after the end of the directive options,
  # as well as the options themselves as a dictionary.
  def self.parse_directive_options(i, lines)
    options = {}
    if i < lines.count
      line = lines[i]
      sline = line.strip()

      while sline.start_with?(":")
        sline[0] = ''
        tokens = sline.split(': ')
        options[tokens[0]] = tokens[1]
        i += 1
        if i < lines.count
          line = lines[i]
          sline = line.strip()
        else
          break
        end
      end
    end
    return i, options
  end
end

# The actual rails controller
class Configurations::BookController < ApplicationController
  def show
    # gets a list of available modules for each language
    @avail_mods = Rails.cache.fetch("odsa_available_modules", expires_in: 6.hours) do
      avail_mods = {}
      OpenDSA::BOOK_LANGUAGES.each do |lang_code, lang_name|
        avail_mods[lang_code] = RSTtoJSON.convert(File.join(OpenDSA::RST_DIRECTORY, lang_code), lang_code)
      end
      avail_mods
    end

    @learning_tools = LearningTool.all.select("id, name")
    @reference_configs = reference_book_configurations()
    @book_metadata = InstBook.get_metadata(current_user.id)

    render
  end

  private

  # Gets a list of book configurations hosted on the OpenDSA server
  # Returns a dictionary containing the name, title, and url of each config file
  def reference_book_configurations()
    return Rails.cache.fetch("odsa_reference_book_configs", expires_in: 6.hours) do
             config_dir = File.join("public", "OpenDSA", "config")
             base_url = request.protocol + request.host_with_port + "/OpenDSA/config/"
             configs = []
             Dir.foreach(config_dir) do |entry|
               if entry.include?("_generated.json") or not File.extname(entry) == '.json'
                 next
               end
               url = base_url + File.basename(entry)
               begin
                 title = JSON.parse(File.read(File.join(config_dir, entry)))["title"]
                 configs << {
                   title: title,
                   name: File.basename(entry, '.json'),
                   url: url,
                 }
               rescue
                 error = Error.new(:class_name => 'book_config_parse_fail',
                                   :message => "Failed to parse #{entry}")
                 error.save!
               end
             end
             configs.sort_by! { |x| x[:title] }
           end
  end
end
