class OdsaUserInteraction < ActiveRecord::Base
  #~ Relationships ............................................................
  belongs_to :inst_book_section_exercise
  belongs_to :inst_course_offering_exercise
  belongs_to :inst_book
  belongs_to :inst_section
  belongs_to :user

  #~ Validation ...............................................................
  validate :required_fields
  
  def required_fields
    
    if not (inst_book_id.present? or inst_course_offering_exercise_id.present?)
      errors.add(:inst_book_id, "or inst_course_offering_exercise_id must be present")
      errors.add(:inst_course_offering_exercise_id, "or inst_book_id must be present")
    end
  end
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  #~ Instance methods .........................................................
  #~ Private instance methods .................................................
end
