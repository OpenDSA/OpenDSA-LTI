class OdsaModuleProgress < ActiveRecord::Base
  #~ Relationships ............................................................
  belongs_to :user
  belongs_to :inst_book
  belongs_to :inst_chapter_module
  belongs_to :lms_access

  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................

  def self.get_progress(user_id, inst_chapter_module_id, inst_book_id)
    unless module_progress = OdsaModuleProgress.find_by(user_id: user_id, inst_chapter_module_id: inst_chapter_module_id)
      module_progress = OdsaModuleProgress.create(user_id: user_id, inst_book_id: inst_book_id,
                                                  inst_chapter_module_id: inst_chapter_module_id)
      module_progress.save!
    end
    module_progress
  end

  #~ Instance methods .........................................................
  def update_proficiency(inst_exercise)
    book_progress = OdsaBookProgress.get_progress(self.user_id, self.inst_book_id)
    # TODO: This only gets progresses for exercises that have been attempted at least once
    bk_sec_exs = self.inst_chapter_module.get_bk_sec_exercises() || []
    module_exercises = bk_sec_exs.collect { |ex| ex.inst_exercise.short_name } || []
    proficient_exercises = book_progress.get_proficient_exercises || []

    self.first_done ||= DateTime.now
    self.last_done = DateTime.now
    update_score(bk_sec_exs)
    self.save!

    last_exercise = false
    if self.proficient_date.nil?
      if module_exercises and proficient_exercises
        if (module_exercises - proficient_exercises).length == 1
          if module_exercises[0] == inst_exercise.short_name
            last_exercise = true
          end
        end
        if (module_exercises - proficient_exercises).empty? or last_exercise
          self.proficient_date = DateTime.now
          self.save!
          return true
        else
          self.save!
          return false
        end
      else
        return false
      end
    else
      return true
    end
  end

  #~ Private instance methods .................................................
  private

  # compute the aggregate score from all of the exercises in the module
  def update_score(bk_sec_exs)
    exercise_progresses = self.inst_chapter_module.get_exercise_progresses(self.user_id)
    score = 0
    total_points = 0
    bk_sec_exs.each do |ex|
      if ex.required
        total_points += ex.points
        prog = exercise_progresses.detect { |p| p.inst_book_section_exercise_id == ex.id }
        if !prog.blank? and prog.proficient?
          score += ex.points
        end
      end
    end
    self.current_score = score / total_points
    if self.current_score > self.highest_score
      self.highest_score = self.current_score
    end

    self.current_score
  end
end
