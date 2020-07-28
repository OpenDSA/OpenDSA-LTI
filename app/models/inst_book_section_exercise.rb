class InstBookSectionExercise < ApplicationRecord
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

  def self.handle_grade_passback(req, res, user_id, inst_book_section_exercise_id)
    ex_progress = OdsaExerciseProgress.find_by(user_id: user_id,
        inst_book_section_exercise_id: inst_book_section_exercise_id)
    if req.replace_request?
      # set a new score for the user
            
      score = Float(req.score.to_s)

      if score < 0.0 || score > 1.0
        res.description = "The score must be between 0.0 and 1.0"
        res.code_major = 'failure'
      else
        # we store exercise scores in the database as an integer
        score = Integer(score * 100)
        ex_progress = OdsaExerciseProgress.find_by(user_id: user_id,
                                                   inst_book_section_exercise_id: inst_book_section_exercise_id)
        if ex_progress.blank?
          ex_progress = OdsaExerciseProgress.new(user_id: user_id,
                                                 inst_book_section_exercise_id: inst_book_section_exercise_id)
        end
        old_score = ex_progress.current_score
        ex_progress.update_score(score)
        ex_progress.save!

        bk_sec_ex = InstBookSectionExercise.includes(:inst_exercise, inst_section: [:inst_chapter_module])
          .find_by(id: inst_book_section_exercise_id)
        inst_chapter_module = bk_sec_ex.inst_section.inst_chapter_module

        # update the score for the module containing the exercise
        mod_progress = OdsaModuleProgress.get_progress(user_id, inst_chapter_module.id, bk_sec_ex.inst_book_id)
        mod_progress.update_proficiency(bk_sec_ex.inst_exercise)

        res.description = "Your old score of #{old_score} has been replaced with #{score}"
        res.code_major = 'success'
      end
    elsif req.read_request?
      # return the score for the user
      res.description = ex_progress.blank? ? "Your score is 0" : "Your score is #{ex_progress.highest_score}"
      res.score = ex_progress.blank? ? 0 : ex_progress.highest_score
      res.code_major = 'success'
    end

    return res
  end

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
