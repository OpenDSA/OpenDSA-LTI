class OdsaUserInteraction < ApplicationRecord
  #~ Relationships ............................................................
  belongs_to :inst_book_section_exercise
  belongs_to :inst_course_offering_exercise
  belongs_to :inst_book
  belongs_to :inst_section
  belongs_to :user
  belongs_to :inst_chapter_module
  belongs_to :inst_module_version
  belongs_to :inst_module_section_exercise

  #~ Validation ...............................................................
  validate :required_fields

  def required_fields
    if not(inst_book_id.present? or inst_course_offering_exercise_id.present? or inst_module_version_id.present?)
      errors.add(:base, "inst_book_id or inst_course_offering_exercise_id or inst_module_version_id must be present")
    end
  end

  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  #~ Instance methods .........................................................
  #~ Private instance methods .................................................
end
