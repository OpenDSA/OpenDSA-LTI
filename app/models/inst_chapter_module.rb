class InstChapterModule < ActiveRecord::Base
  #~ Relationships ............................................................
  belongs_to :inst_chapter
  belongs_to :inst_module
  has_many :inst_sections, dependent: :destroy
  has_many :odsa_module_progresses, inverse_of: :inst_chapter_module, dependent: :destroy

  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  #~ Instance methods .........................................................

  # --------------------------------------------------------------------------
  # clone inst_chapter_module
  def clone(book, chapter)
    ch_mod = InstChapterModule.new
    ch_mod.inst_chapter_id = chapter.id
    ch_mod.inst_module_id = self.inst_module_id
    ch_mod.module_position = self.module_position
    ch_mod.save

    inst_sections.each do |section|
      inst_section = section.clone(book, ch_mod)
    end
  end

  # --------------------------------------------------------------------------
  # gets all the exercises in one module
  def get_exercises_list
    exercises_list = []
    inst_sections.each do |inst_section|
      exercises_ids = inst_section.inst_book_section_exercises.collect(&:inst_exercise_id).compact
      exercises_objs = InstExercise.where(id: exercises_ids)
      exercises_list.concat exercises_objs.collect(&:short_name)
    end
    return exercises_list
  end

  def total_points
    total_points = 0
    inst_sections.each do |inst_section|
      inst_section_points = inst_section.total_points
      if inst_section_points == nil
        inst_section_points = 0
      end
      total_points = total_points + inst_section_points
    end
    return total_points
  end


  #~ Private instance methods .................................................
end
