require "find"
require "json/ext"
require "json"
require "nokogiri"
require_relative "avembed"
require_relative "inlineav"

module RstParser

  RST_DIR = File.join("public", "OpenDSA", "RST", "en")
  #RST_DIR = File.join("..", "OpenDSA", "RST", "en")

  INCLUDE_DIRS = {
      "AlgAnal": "Algorithm Analysis",
      "Background": "Introduction and Mathematical Background",
      "Binary": "Binary Trees",
      "Biography": "Biographies",
      "Bounds": "Lower Bounds",
      "BTRecurTutor": "Binary Trees Recursion",
      "Design": "Design I and II",
      "Files": "File Processing",
      "FormalLang": "Formal Languages",
      "General": "General Trees",
      "Graph": "Graphs",
      "Hashing": "Hashing",
      "Indexing": "Indexing",
      "List": "Linear Structures",
      "MemManage": "Memory Management",
      "NP": "Limits to Computing",
      "PL": "Programming Languages",
      "PointersJava": "PointersJava",
      "RecurTutor": "Recursion",
      "Searching": "Searching I and II",
      "SearchStruct": "Search Structures",
      "SeniorAlgAnal": "Advanced Analysis",
      "Sorting": "Sorting",
      "Spatial": "Spatial Data Structures",
      "Tutorials": "Programming Tutorials",
      "Development": "Under Development"
  }

  EX_RE = Regexp.new("^(\.\. )(avembed|inlineav):: (([^\s]+\/)*([^\s.]*)(\.html)?) (ka|ss|pe)")

  # Retrieves info about all exercises
  def self.get_exercise_info
    return Rails.cache.fetch("odsa_all_exercises", expires_in: 1.year) do
      exercises = get_exercises()

      inst_exercises = InstExercise.all()
      inst_ex_map = {}
      inst_exercises.each do |ex|
        inst_ex_map[ex.short_name] = ex.id
      end

      exercises.each do |chapter, mod|
        mod.each do |mod_name, ex_list|
          ex_list.each do |ex|
            if inst_ex_map.has_key?(ex.short_name)
              ex.id = inst_ex_map[ex.short_name]
            else
              inst_ex = InstExercise.find_by(short_name: ex.short_name)
              if inst_ex.blank?
                # the exercise has not been saved to the database yet
                inst_ex = InstExercise.new
                inst_ex.short_name = ex.short_name
                inst_ex.name = ex.long_name
                inst_ex.save
              end
              inst_ex_map[ex.short_name] = inst_ex.id
              ex.id = inst_ex.id
            end
          end
        end
      end
      return exercises
    end
  end

  # Gets a hash map where the key is the short_name of the exercise
  # and the value is an ExerciseInfo object (located in rst_parser.rb)
  def self.get_exercise_map
    return Rails.cache.fetch("odsa_all_exercises_map", expires_in: 1.year) do
      exercises = get_exercise_info
      ex_map = {}
      exercises.each do |chapter, modules|
        modules.each do |mod, exs|
          exs.each do |ex|
            ex_map[ex.short_name] = ex
          end
        end
      end
      return ex_map
    end
  end

  def self.get_exercises
    exercises = {}
    INCLUDE_DIRS.each do |short_name, long_name|
      exercises[long_name] = {}
      full_dir = File.join(RST_DIR, short_name.to_s)
      Find.find(full_dir) do |path|
        if path.end_with?(".rst")
          extract_exercises(path, exercises[long_name])
        end
      end
      if exercises[long_name].empty?
        exercises.delete(long_name)
      end
    end
    return exercises
  end

  def self.extract_exercises(rst_path, exercises)
    lines = File.readlines(rst_path)
    i = 0
    mod_lname = ""
    mod_sname = File.basename(rst_path, '.rst')
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

    exs = []
    while i < lines.count
      line = lines[i]
      sline = line.strip()

      if sline == ""
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

        options = {}
        i += 1
        # parse directive options
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

        if options.has_key?('long_name')
          ex_lname = options.delete('long_name')
        else
          ex_lname = ex_sname
        end

        if (directive == 'inlineav' and ex_type == 'ss')
          links = []
          if options.has_key?('scripts')
            if options.has_key?('links')
              options.delete('links').split(' ').each do |l|
                links << File.join("", "OpenDSA", l)
              end
            end
            scripts = []
            options.delete('scripts').split(' ').each do |s|
              scripts << File.join("", "OpenDSA", s)
            end
            exs << InlineAv.new(ex_sname, ex_lname, ex_type, mod_sname, links, scripts)
          end
        elsif directive == 'avembed'
          av_path = File.join("", "OpenDSA", identifier)
          rel_path = 'public' + av_path
          if File.exist?(rel_path)
            dimensions = find_av_dimensions(rel_path)
            if dimensions == nil
              # couldn't find dimensions; just use defaults
              exs << AvEmbed.new(ex_sname, ex_lname, ex_type, mod_sname, av_path)
            else
              exs << AvEmbed.new(ex_sname, ex_lname, ex_type, mod_sname, av_path,
                                 dimensions[:width], dimensions[:height])
            end
          end
        end
      else
        i += 1
      end
    end
    if not exs.empty?
      exercises[mod_lname] = exs
    end
  end
end

private

def find_av_dimensions(av_path)
  doc = File.open(av_path) do |f| 
    Nokogiri::HTML(f)
  end
  attrib = doc.at('body').attributes
  if attrib.has_key?('data-width') and attrib.has_key?('data-height')
    return {
              'width': attrib['data-width'].value.to_i, 
              'height': attrib['data-height'].value.to_i
            }
  end
  return nil
end

#puts(RstParser.get_exercises().to_json)