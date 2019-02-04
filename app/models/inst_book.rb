#~ Relationships ............................................................
#~ Validation ...............................................................
#~ Constants ................................................................
#~ Hooks ....................................................................
#~ Class methods ............................................................
#~ Instance methods .........................................................
#~ Private instance methods .................................................
class InstBook < ActiveRecord::Base
  enum book_type: {Complete: 0, Exercises: 1}

  #~ Relationships ............................................................
  belongs_to :course_offering, inverse_of: :inst_books
  belongs_to :user, inverse_of: :inst_books
  has_many :inst_chapters, dependent: :destroy
  has_many :inst_book_section_exercises, dependent: :destroy
  has_many :odsa_user_interactions, dependent: :destroy
  has_many :odsa_book_progresses, dependent: :destroy
  has_many :odsa_module_progresses, dependent: :destroy
  has_many :odsa_exercise_attempts, dependent: :destroy

  paginates_per 100

  scope :template, -> { where "template = ?", 1 }

  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  def self.save_data_from_json(json, current_user, inst_book = nil)
    book_data = json
    update_mode = false
    inst_book_id = inst_book
    options = {}
    options['build_dir'] = book_data['build_dir'] || "Books"
    options['code_dir'] = book_data['code_dir'] || "SourceCode/"
    options['lang'] = book_data['lang'] || "en"
    options['code_lang'] = book_data['code_lang'] || {}
    options['build_JSAV'] = book_data['build_JSAV'] || false
    options['tabbed_codeinc'] = book_data['tabbed_codeinc'] || true
    options['build_cmap'] = book_data['build_cmap'] || false
    options['suppress_todo'] = book_data['suppress_todo'] || true
    options['assumes'] = book_data['assumes'] || "recursion"
    options['dispModComp'] = book_data['dispModComp'] || true
    options['glob_exer_options'] = book_data['glob_exer_options'] || {}

    if inst_book_id == nil
      b = InstBook.new
      b.user_id = current_user.id
      b.template = true
    else
      b = InstBook.find_by(id: inst_book_id)
      update_mode = true
    end
    b.title = book_data['title']
    b.desc = book_data['desc']

    require 'json'
    b.options = options.to_json
    b.save

    chapters = book_data['chapters']

    ch_position = 0
    chapters.each do |k, v|
      inst_chapter = InstChapter.save_data_from_json(b, k, v, ch_position, update_mode)
      ch_position += 1
    end
  end

  def self.get_metadata(user_id)
    return InstBook.where(user_id: user_id)
             .joins("LEFT JOIN course_offerings ON course_offering_id = course_offerings.id")
             .joins("LEFT JOIN terms ON term_id = terms.id")
             .joins("LEFT JOIN courses ON course_id = courses.id")
             .select('inst_books.id, inst_books.title, inst_books.created_at,
                inst_books.updated_at, inst_books.template, inst_books.desc,
                inst_books.last_compiled, course_offering_id, label, courses.name AS course_name,
                courses.number AS course_number, terms.slug AS term')
             .order('inst_books.template DESC, inst_books.title ASC, terms.starts_on ASC')
  end

  #~ Instance methods .........................................................

  # Checks for modules listed in the book configuration for which an RST
  # file doesn't exist. This can happen if an RST file has been renamed, moved,
  # deleted, etc. since the configuration was created.
  def validate_configuration
    lang = JSON.parse(self.options)['lang'] || 'en'
    rst_folder = File.join('public', 'OpenDSA', 'RST', lang)
    missing_modules = []
    chapters = InstChapter.includes(inst_chapter_modules: [:inst_module])
      .references(inst_chapter_modules: [:inst_module])
      .where(inst_book_id: self.id)
    for chapter in chapters
      for mod in chapter.inst_chapter_modules
        mod_path = mod.inst_module.path
        unless File.file?(File.join(rst_folder, mod_path + '.rst'))
          missing_modules << {path: mod_path, name: mod.inst_module.name}
        end
      end
    end
    return missing_modules
  end

  def to_builder
    Jbuilder.new do |json|
      json.set! :inst_book_id, self.id
      json.set! :title, self.title
      json.set! :desc, self.desc
      json.set! :last_compiled, self.last_compiled.try(:strftime, "%Y-%m-%d %H:%m:%S")
      options = self.options
      if options != nil && options != "null"
        options = eval(options)
        options.each do |key, value|
          json.set! key, value
        end
      end

      # chapters
      json.chapters do
        for inst_chapter in self.inst_chapters.order('position')
          chapter_name = inst_chapter.name
          # chapter object
          json.set! chapter_name do
            for inst_chapter_module in inst_chapter.inst_chapter_modules.order('module_position')
              module_path = InstModule.where(:id => inst_chapter_module.inst_module_id).first.path

              # module Object
              json.set! module_path do
                # sections
                json.sections do
                  sections = inst_chapter_module.inst_sections
                  if sections.empty?
                    json.nil!
                  else
                    for inst_section in inst_chapter_module.inst_sections
                      section_name = inst_section.name

                      # section object
                      json.set! section_name do
                        json.set! :showsection, inst_section.show
                        learning_tool = inst_section.learning_tool
                        json.exercises do
                          if learning_tool
                            exercise = inst_section.inst_book_section_exercises.first
                            json.set! inst_section.resource_name do
                              json.set! :points, exercise.points.to_f
                            end
                          else
                            exercises = inst_section.inst_book_section_exercises
                            if !exercises.empty?
                              for inst_book_section_exercise in exercises
                                exercise_name = InstExercise.where(:id => inst_book_section_exercise.inst_exercise_id).first.short_name
                                json.set! exercise_name do
                                  json.set! :required, inst_book_section_exercise.required
                                  json.set! :points, inst_book_section_exercise.points.to_f
                                  json.set! :threshold, inst_book_section_exercise.threshold.to_f
                                  options = inst_book_section_exercise.options
                                  if options != nil && options != "null"
                                    json.set! :exer_options, eval(options)
                                  end
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  # --------------------------------------------------------------------------
  # clone book configuration
  def clone(current_user)
    b = InstBook.new
    b.title = self.title
    b.desc = self.desc
    b.options = self.options
    b.user_id = current_user.id
    b.save

    inst_chapters.each do |chapter|
      inst_chapter = chapter.clone(b)
    end
    return b
  end

  def total_points
    total_points = 0
    inst_chapters.each do |chapter|
      chapter_points = chapter.total_points
      if chapter_points == nil
        chapter_points = 0
      end
      total_points = total_points + chapter_points
    end
    return total_points
  end

  def title_with_created_at
    return "#{title} (created #{created_at})"
  end

  #~ Private instance methods .................................................
end
