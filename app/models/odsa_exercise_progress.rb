class OdsaExerciseProgress < ActiveRecord::Base
  #~ Relationships ............................................................
  belongs_to :inst_book_section_exercise
  belongs_to :inst_course_offering_exercise
  belongs_to :user

  #~ Validation ...............................................................
  validate :required_fields

  def required_fields
    if not(inst_book_section_exercise_id.present? or inst_course_offering_exercise_id.present?)
      errors.add(:inst_book_section_exercise_id, "or inst_course_offering_exercise_id must be present")
      errors.add(:inst_course_offering_exercise_id, "or inst_book_section_exercise_id must be present")
    end
  end

  #~ Constants ................................................................
  #~ Hooks ....................................................................
  after_initialize :set_defaults, unless: :persisted?
  #~ Class methods ............................................................
  #~ Instance methods .........................................................
  def set_defaults
    self.current_score ||= 0
    self.highest_score ||= 0
    self.total_correct ||= 0
    self.total_worth_credit ||= 0
  end

  # update the current_score, highest_score, and proficient date
  def update_score(new_score)
    self.current_score = new_score
    now = DateTime.now
    if new_score > self.highest_score
      self.highest_score = new_score
      if new_score == 100
        self.proficient_date = now
      end
    end
    self.first_done ||= now
    self.last_done = now
  end

  def proficient?
    return ((self.proficient_date != nil) and self.proficient_date.year > 0)
  end

  #~ Private instance methods .................................................

end
