class OdsaExerciseAttempt < ActiveRecord::Base
  #~ Relationships ............................................................
  belongs_to :user
  belongs_to :inst_book
  belongs_to :inst_section
  belongs_to :inst_book_section_exercise

  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  after_save :update_exercise_progress
  #~ Class methods ............................................................
  #~ Instance methods .........................................................
  def update_exercise_progress
      exercise_progress = self.get_exercise_progress

      exercise_progress.last_done = DateTime.now

      exercise_progress.save
  end

  def get_exercise_progress
    return OdsaExerciseProgress.where("user_id=? and inst_book_section_exercise_id=?",
                                                 user.id,
                                                 inst_book_section_exercise.id).first
  end
  #~ Private instance methods .................................................

 end