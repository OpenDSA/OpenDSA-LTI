class OdsaBookProgress < ApplicationRecord
  #~ Relationships ............................................................
  belongs_to :user
  belongs_to :inst_book
  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  #~ Instance methods .........................................................
  def update_started(inst_exercise)
    unless self.started?(inst_exercise)
      if self.started_exercises.to_s.strip.length == 0
        self.started_exercises = inst_exercise.short_name
      else
        self.started_exercises += ',' + inst_exercise.short_name
      end
    end
    self.save
  end

  def update_proficiency(exercise_progress)
    inst_book_section_exercise = InstBookSectionExercise.find_by(id: exercise_progress.inst_book_section_exercise_id)
    inst_exercise = InstExercise.find_by(id: inst_book_section_exercise.inst_exercise_id)

    threshold = inst_book_section_exercise.threshold
    exercise_points = inst_book_section_exercise.points
    highest_score = exercise_progress.highest_score
    proficient = false
    if (exercise_points == 0) || (exercise_points != 0 && highest_score >= threshold)
      proficient = true
      unless self.proficient?(inst_exercise)
        if self.proficient_exercises.to_s.strip.length == 0
          self.proficient_exercises = inst_exercise.short_name
        else
          self.proficient_exercises += ',' + inst_exercise.short_name
        end
      end
    end
    self.save
    return proficient
  end

  def started?(inst_exercise)
    started_exercises = self.started_exercises.split(',')
    return started_exercises.include? inst_exercise.short_name
  end

  def proficient?(inst_exercise)
    proficient_exercises = self.get_proficient_exercises
    return proficient_exercises.include? inst_exercise.short_name
  end

  # Return array of exercises names
  def get_proficient_exercises
    return self.proficient_exercises.split(',')
  end

  def self.get_progress(user_id, inst_book_id)
    unless book_progress = OdsaBookProgress.find_by(user_id: user_id, inst_book_id: inst_book_id)
      book_progress = OdsaBookProgress.new(user_id: user_id, inst_book_id: inst_book_id)
      book_progress.save!
    end
    book_progress
  end

  #~ Private instance methods .................................................
end
