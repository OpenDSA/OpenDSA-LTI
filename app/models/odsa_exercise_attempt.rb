class OdsaExerciseAttempt < ActiveRecord::Base
  #~ Relationships ............................................................
    belongs_to :inst_book_section_exercise
    belongs_to :user

  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  #~ Instance methods .........................................................
  #~ Private instance methods .................................................


 def book_progress

      last_exercise = OdsaExerciseAttempt.last

      uid = last_exercise.user_id
      exid = last_exercise.inst_book_section_exercise_id

      proficient = last_exercise.earned_proficiency
      create = last_exercise.created_at
      update = last_exercise.updated_at

      bookid = OdsaUserInteraction.last.inst_book_id

    if OdsaBookProgress.exists?(user_id: "#{uid}", book_id: "#{bookid}")

      book_progress = OdsaBookProgress.where(user_id: "#{uid}", book_id: "#{bookid}")
      ex_s = book_progress.started_exercises
      ex_p = book_progress.all_proficient_exercises

      if ex_s.split(',').includes?(exid) && proficient == 1

        ex_p = ex_p + ", #{exid}"
        book_progress.update!(:all_proficient_exercises, "#{ex_p}")
        book_progress.update!(:updated_at, "#{update}")


      elsif proficient == 1

        ex_s = ex_s + ", #{exid}"
        ex_p = ex_p + ", #{exid}"

        book_progress.update!(:started_exercises, "#{ex_s}")
        book_progress.update!(:all_proficient_exercises, "#{ex_p}")
        book_progress.update!(:updated_at, "#{update}")

      else

        book_progress.update!(:updated_at, "#{update}")

      end

    else

      if proficient == 1

        book_update = OdsaBookProgress.create(user_id: "#{uid}", book_id: "#{bookid}",
        started_exercises: "#{exid}", all_proficient_exercises: "#{exid}",
        created_at: "#{create}", updated_at: "#{update}")

      else

        unpid = nil

        book_update = OdsaBookProgress.create(user_id: "#{uid}", book_id: "#{bookid}",
        started_exercises: "#{exid}", all_proficient_exercises: "#{unpid}",
        created_at: "#{create}", updated_at: "#{update}")

      end

    end



end
