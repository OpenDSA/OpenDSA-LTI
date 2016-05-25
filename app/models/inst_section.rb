class InstSection < ActiveRecord::Base
  #~ Relationships ............................................................
  belongs_to :inst_chapter_module
  has_many :inst_book_section_exercises
  has_many :odsa_student_extensions
  has_many :odsa_user_interactions
  has_many :inst_books_by_inst_book_section_exercises, :source => :inst_book, :through => :inst_book_section_exercises
  has_many :users_by_odsa_student_extensions, :source => :user, :through => :odsa_student_extensions
  has_many :inst_book_section_exercises_by_odsa_user_interactions, :source => :inst_book_section_exercise, :through => :odsa_user_interactions
  has_many :inst_books_by_odsa_user_interactions, :source => :inst_book, :through => :odsa_user_interactions
  has_many :users_by_odsa_user_interactions, :source => :user, :through => :odsa_user_interactions

  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  def self.save_data_from_json(book, module_rec, inst_chapter_module_rec, section_name, section_obj, section_position)
    inst_sec = InstSection.new
    inst_sec.inst_module_id = module_rec.id
    inst_sec.inst_chapter_module_id = inst_chapter_module_rec.id
    inst_sec.name = section_name
    inst_sec.save

    gradable_ex = false
    gradable_sec = false
    section_obj.each do |k, v|
      if v.is_a?(Hash) && !v.empty?
        gradable_ex = InstExercise.save_data_from_json(book, inst_sec, k, v)
        gradable_sec = true if gradable_ex
      end
    end
    inst_sec.gradable = gradable_sec
    inst_sec.save
  end
  #~ Instance methods .........................................................
  #~ Private instance methods .................................................
end
