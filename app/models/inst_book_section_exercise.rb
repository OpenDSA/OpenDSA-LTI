class InstBookSectionExercise < ActiveRecord::Base
  #~ Relationships ............................................................
  belongs_to :inst_book
  belongs_to :inst_section
  has_many :odsa_exercise_attempts
  has_many :odsa_exercise_progresses
  has_many :odsa_user_interactions
  has_many :users_by_odsa_exercise_attempts, :source => :user, :through => :odsa_exercise_attempts
  has_many :users_by_odsa_exercise_progress, :source => :user, :through => :odsa_exercise_progresses
  has_many :inst_books, :through => :odsa_user_interactions
  has_many :inst_sections, :through => :odsa_user_interactions
  has_many :users_by_odsa_user_interactions, :source => :user, :through => :odsa_user_interactions

  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  after_save do
    if points > 0
      inst_section.gradable = true
      inst_section.save
    end
  end

  #~ Class methods ............................................................
  #~ Instance methods .........................................................
  #~ Private instance methods .................................................

end
