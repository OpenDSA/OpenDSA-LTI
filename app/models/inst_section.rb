class InstSection < ActiveRecord::Base
  #~ Relationships ............................................................
  belongs_to :inst_chapter_module
  has_many :inst_book_section_exercises, dependent: :destroy
  has_many :odsa_student_extensions
  has_many :odsa_user_interactions, dependent: :destroy
  has_many :odsa_exercise_attempts, dependent: :destroy
  # has_many :inst_books_by_inst_book_section_exercises, :source => :inst_book, :through => :inst_book_section_exercises
  # has_many :users_by_odsa_student_extensions, :source => :user, :through => :odsa_student_extensions
  # has_many :inst_book_section_exercises_by_odsa_user_interactions, :source => :inst_book_section_exercise, :through => :odsa_user_interactions
  # has_many :inst_books_by_odsa_user_interactions, :source => :inst_book, :through => :odsa_user_interactions
  # has_many :users_by_odsa_user_interactions, :source => :user, :through => :odsa_user_interactions

  #~ Validation ...............................................................

  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  def self.save_data_from_json(book, module_rec, inst_chapter_module_rec, section_name, section_obj, section_position, update_mode=false)
    inst_sec = InstSection.where("inst_chapter_module_id = ? AND inst_module_id = ? AND name = ?", inst_chapter_module_rec.id, module_rec.id, section_name).first

    if !update_mode or (update_mode and !inst_sec)
      inst_sec = InstSection.new
      inst_sec.inst_module_id = module_rec.id
      inst_sec.inst_chapter_module_id = inst_chapter_module_rec.id
      inst_sec.name = section_name
    end
    inst_sec.learning_tool = section_obj['learning_tool']
    inst_sec.resource_type = section_obj['resource_type']
    inst_sec.resource_name = section_obj['resource_name']
    inst_sec.show = section_obj.key?('showsection') ? section_obj['showsection'] : true
    inst_sec.soft_deadline = section_obj['soft_deadline']
    inst_sec.hard_deadline = section_obj['hard_deadline']
    inst_sec.save

    # learning tool section
    if section_obj['learning_tool'] and section_obj['resource_type'] == 'external_assignment'
     InstExercise.save_data_from_json(book, inst_sec, section_name, section_obj, update_mode)
    else # OpenDSA section
      section_obj.each do |k, v|
       InstExercise.save_data_from_json(book, inst_sec, k, v, update_mode) if v.is_a?(Hash)
      end
    end

  end
  #~ Instance methods .........................................................

  # -------------------------------------------------------------
  # TODO
  # check that only one child exercise in inst_book_section_exercises table
  # is gradable (has points > 0)
  def one_gradable_ex_only
  end

  # -------------------------------------------------------------
  # return the gradable exercise name from inst_exercises table and
  # id from inst_book_section_exercises table
  def get_gradable_ex
    inst_bk_sec_ex = InstBookSectionExercise.where("inst_section_id = ? AND points > 0 AND inst_exercise_id IS NOT NULL", id).first
    inst_ex = InstExercise.where(id: inst_bk_sec_ex['inst_exercise_id']).first
    {'ex_name' => inst_ex.short_name, "inst_bk_sec_ex" => inst_bk_sec_ex.id}
  end

  # -------------------------------------------------------------
  # clone inst_section
  def clone(inst_book, inst_chapter_module)
    section = InstSection.new
    section.inst_chapter_module_id = inst_chapter_module.id
    section.inst_module_id = self.inst_module_id
    section.short_display_name = self.short_display_name
    section.name = self.name
    section.position = self.position
    section.gradable = self.gradable
    section.soft_deadline = self.soft_deadline
    section.hard_deadline = self.hard_deadline
    section.time_limit = self.time_limit
    section.show = self.show
    section.learning_tool = self.learning_tool
    section.resource_type = self.resource_type
    section.resource_name = self.resource_name
    section.save

    inst_book_section_exercises.each do |book_section_exercise|
      inst_book_section_exercise = book_section_exercise.clone(inst_book, section)
    end
  end

  def total_points
    total_points = 0
    inst_book_section_exercises.each do |bk_sec_ex|
      bk_sec_ex_points = bk_sec_ex.points
      if bk_sec_ex_points == nil
        bk_sec_ex_points = 0
      end
      total_points = total_points + bk_sec_ex_points
    end
    return total_points
  end

  #~ Private instance methods .................................................
end
