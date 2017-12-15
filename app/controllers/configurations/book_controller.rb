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

# The actual rails controller
class Configurations::BookController < ApplicationController

    def show
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

        @languages = {
            "en": "English",
            "fr": "Français",
            "pt": "Português",
            "fi": "Suomi",
            "sv": "Svenska"
        }

        @availMods = Rails.cache.fetch("odsa_available_modules", expires_in: 1.day) do
            availMods = {}
            @languages.each do |lang_code, lang_name|
                availMods[lang_code] = RSTtoJSON.convert("./RST/#{lang_code}", lang_code)
            end
            availMods
        end

        @learning_tools = LearningTool.all.select("id, name")
        @reference_configs = reference_book_configurations()

        render
    end

    private

    def reference_book_configurations()
        return Rails.cache.fetch("odsa_reference_book_configs", expires_in: 1.day) do
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
            configs.sort_by! { |x| x[:title] }
        end
    end
end
