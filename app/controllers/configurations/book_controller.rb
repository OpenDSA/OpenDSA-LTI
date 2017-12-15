require 'json'

# Helper classes
class RSTtoJSON
    def self.convert(path, lang)
        json = {} # The json for this directory
        json["children"] = []
        json["type"] = "chapter"
        json["path"] = path
        json["text"] = File.basename(path)
        json["id"] = path.sub(/.\/RST\/#{lang}\/?/, '')
        Dir.foreach(path) do |entry|
            child = {}
            if entry == '.' or entry == '..'
                # Skip over the current and parent directory
                next
            end
            # Concatenate the subpath with the entry and path
            subpath = File.join(path, entry)
            if File.file?(subpath) and File.extname(subpath) == '.rst'
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
    EX_RE ||= Regexp.new("^(\.\. )(avembed|inlineav):: (([^\s]+\/)*([^\s.]*)(\.html)?) (ka|ss|pe)")
    EXTR_RE ||= Regexp.new("^(\.\. )(extrtoolembed:: '([^']+)')")
    SECTION_RE ||= Regexp.new('^-+$')
    URI_ESCAPE_RE ||= Regexp.new("[^#{URI::PATTERN::UNRESERVED}']")

    def self.extract_module_info(rst_path, lang)

        lines = File.readlines(rst_path)
        i = 0
        mod_lname = ""
        mod_sname = File.basename(rst_path, '.rst')
        mod_path = rst_path.sub("./RST/#{lang}/", '').sub('.rst', '')
        mod = {
            id: URI.escape(mod_path, URI_ESCAPE_RE).gsub(/[%']/, ''),
            path: mod_path,
            short_name: mod_sname,
            children: [],
            type: 'module'
        }

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
              id: URI.escape("#{mod_path}|sect|#{sectName}", URI_ESCAPE_RE).gsub(/[%']/, '')
            }
            mod[:children] << curr_section
            i += 1
            next
          end

          match_data = EX_RE.match(sline)
          if match_data != nil
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
                id: URI.escape("#{mod_path}||#{ex_sname}", URI_ESCAPE_RE).gsub(/[%']/, '')
            }
          else
            match_data = EXTR_RE.match(sline)
            if match_data != nil
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
                    id: URI.escape("#{mod_path}||#{ex_name}", URI_ESCAPE_RE).gsub(/[%']/, '')
                }
            else
                i += 1
            end
          end
        end
        return mod
    end

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

# Class which represents a book configuration
class BookConfiguration
    @@requiredMembers = ["chapters", "title"]# Required members within the configuration
    # Not sure if these are actually required so modify if needed

    # Constructor
    def initialize(configPath, fileName, json)
        @json = json # The json in the form of a hash object
        @configPath = configPath # The path to the configuration folder
        @fullPath = File.join(configPath, fileName)
    end

    # The path of this BookConfiguration
    def path
        return @fullPath
    end

    def valid?() # Checks to see if the json is a valid configuration
        # TODO Should use this method to check if JSON is valid
        return true # Just returning true for now.
        @@requiredMembers.each do |member|
            if @json.key?(member) == false #If it is missing a member
                return false
            end
        end
        # Should have returned false if there were required members missing from the configuration
        # Now check if all of the modules are valid

    end

    # Checks to see if the module exists on the system. Should be used in the valid? method
    def self.validModule(path)
        return File.exists?(path)
    end

    # Saves this book configuration
    def save(fileName="JSON.txt") #TODO remove default JSON.txt:
        # It's purpose is just to keep old code from breaking

        # Just open the file with write permissions
        newConfigFile = File.open(fileName, "w")
        # Write file and close it
        # TODO make sure output is up to the OpenDSA standard
        newConfigFile.write(JSON.pretty_generate(@json))
        newConfigFile.close
    end
end

# Class that manages book configurations
class BookConfigurationManager
    # Sets the path of the configuration folder that should be managed
    def initialize(configPath)
        @configPath = configPath
    end

    def configExists?(fileName)
        return File.exists?(path(fileName))
    end

    def path(fileName)
        return File.join(@configPath, fileName)
    end

    # Creates a new book configuration and saves it
    # Returns true or false based on whether or not it was saved
    def newBookConfig(fileName, json) # The file name and the json as a hash
        newConfig = BookConfiguration.new(@configPath, fileName, json)
        if newConfig.valid? && !configExists?(fileName)
            # Check if the json is valid the config doesn't exist
            newConfig.save(path(fileName))
            return true
        else
            return false
        end
    end

    def list
        # Create the hash for the configuration files
        files = Hash.new
        # Iterate over all the entries within this directory
        Dir.foreach(@configPath) do |entry|
            if entry == '..' or entry == '.'
                next # Obviously skip over these entries
            end
            # Subpath is just a simple concatenation
            subpath = File.join(@configPath, entry)
            # Only return files that are not LMSconfigurations and are folders
            if File.file?(subpath) && !entry.include?("LMSconf")
                files[entry] = nil # Just nil for right now but could be used
                    # in the future to associate information with the files
            end
        end
        return files
    end

    def read(name)
        return JSON.parse(File.read(File.join(@configPath, name)))
    end
end

# The actual rails controller
class Configurations::BookController < ApplicationController

    def show
        @availMods = {}
        @languages = {
            "en": "English",
            "fr": "Français",
            "pt": "Português",
            "fi": "Suomi",
            "sv": "Svenska"
        }
        @languages.each do |lang_code, lang_name|
            @availMods[lang_code] = RSTtoJSON.convert("./RST/#{lang_code}", lang_code)
        end
        @code_languages = {
            "Java": {
                "ext": [
                    "java"
                ],
                "label": "Java",
                "lang": "java"
            },
            "Processing": {
                "ext": [
                    "pde"
                ],
                "label": "Processing",
                "lang": "java"
            },
            "Java_Generic": {
                "ext": [
                    "java"
                ],
                "label": "Java (Generic)",
                "lang": "java"
            },
            "C++": {
                "ext": [
                    "cpp",
                    "h"
                ],
                "label": "C++",
                "lang": "C++"
            },
            "Pseudo": {
                "ext": [
                    "txt"
                ],
                "label": "Pseudo Code",
                "lang": "pseudo"
            },
            "C": {
                "ext": [
                    "c",
                    "h"
                ],
                "label": "C",
                "lang": "c"
            },
            "Python": {
                "ext": [
                    "py"
                ],
                "label": "Python",
                "lang": "python"
            },
            "JavaScript": {
                "ext": [
                    "js"
                ],
                "label": "JavaScript",
                "lang": "javascript"
            }
        }
        @learning_tools = LearningTool.all.select("id, name")
        @reference_configs = reference_book_configurations()
        render
    end

    # This action should be deleted and configuraiton json file should be send directly to edit action for editing
    def create_redirect
        redirect_to :book_config_cerate
    end

    def create
        # If this is a HTTP post request
        if request.post?
            # request.params will be the json object sent in the form of a Hash
            json = request.POST
            # Get the configuration
            configuration = json["config"]
            if !configuration
                render json: {saved: false, message: "Did not give a configuration to save."}
            end
            # Get the name for the configuration
            name = json["name"]
            if !name
                render json: {saved: false, message: "Did not give a name for the configuration."}
            end
            # Create a new manager to manage the config directory
            manager = BookConfigurationManager.new("./Configuration")
            # 'saved' will be true if the new book configuration is saved
            render json: {saved: manager.newBookConfig(name+".txt", configuration)}
        end

        # Rails makes GET the default for the template
    end

    def edit
        if request.post?

        end

        # Rails makes GET the default for the template
    end

    # Returns JSON which represents the folder structure within the RST directory
    def modules
        render json: RSTtoJSON.convert("./RST")
    end

    def load
        manager = BookConfigurationManager.new("./Configuration")
        render json: manager.read(params["name"])
    end

    # Returns JSON where each key is an existing configuration file name
    def configs
        manager = BookConfigurationManager.new("./Configuration")
        render json: manager.list
    end

    private

    def reference_book_configurations()
        config_dir = File.join("public", "OpenDSA", "config")
        base_url = request.protocol + request.host_with_port + "/OpenDSA/config/"
        configs = []
        Dir.foreach(config_dir) do |entry|
            if entry.include?("_generated.json") or not File.extname(entry) == '.json'
                next
            end
            url = base_url + File.basename(entry)
            title = JSON.parse(File.read(File.join(config_dir, entry)))["title"]
            configs << {
                title: title,
                name: File.basename(entry, '.json'),
                url: url
            }
        end
        return configs.sort_by! { |x| x[:title] }
    end
end
