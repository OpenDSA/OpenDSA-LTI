class OdsaModuleProgress < ActiveRecord::Base
  #~ Relationships ............................................................
  belongs_to :user
  belongs_to :inst_book
  belongs_to :inst_chapter_module

  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  #~ Instance methods .........................................................
  def update_proficiency(inst_exercise)
    book_progress = OdsaBookProgress.where(user: user,inst_book: inst_book).first
    module_exercises = inst_chapter_module.get_exercises_list || []
    proficient_exercises = book_progress.get_proficient_exercises || []

    self.first_done ||= DateTime.now
    self.last_done = DateTime.now

    last_exercise = false
    if self.proficient_date.nil?
      if module_exercises and proficient_exercises
        if (module_exercises - proficient_exercises).length == 1
          if module_exercises[0] == inst_exercise.id
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
end
