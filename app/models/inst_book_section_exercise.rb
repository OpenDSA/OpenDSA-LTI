class InstBookSectionExercise < ActiveRecord::Base
  #~ Relationships ............................................................
  belongs_to :inst_book
  belongs_to :inst_section
  belongs_to :inst_exercise      # I define this relation
  has_many :odsa_user_interactions, dependent: :destroy
  has_many :odsa_exercise_attempts, dependent: :destroy
  has_many :odsa_exercise_progresses, dependent: :destroy
  # has_many :users_by_odsa_exercise_attempts, :source => :user, :through => :odsa_exercise_attempts
  # has_many :users_by_odsa_exercise_progress, :source => :user, :through => :odsa_exercise_progresses
  # has_many :inst_books, :through => :odsa_user_interactions
  # has_many :inst_sections, :through => :odsa_user_interactions
  # has_many :users_by_odsa_user_interactions, :source => :user, :through => :odsa_user_interactions

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
  # -------------------------------------------------------------
  # clone inst_book_section_exercise
  def clone(inst_book, inst_section)
    book_section_exercise = InstBookSectionExercise.new
    book_section_exercise.inst_section_id = inst_section.id
    book_section_exercise.inst_book_id = inst_book.id
    book_section_exercise.inst_exercise_id = self.inst_exercise_id
    book_section_exercise.points = self.points
    book_section_exercise.required = self.required
    book_section_exercise.threshold = self.threshold
    book_section_exercise.options = self.options
    book_section_exercise.save
  end

  def get_chapter_module
    return InstChapterModule.find_by(id: inst_section.inst_chapter_module_id)
  end

  #~ Private instance methods .................................................

end
