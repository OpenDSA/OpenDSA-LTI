  # create_table "odsa_exercise_attempts", force: true do |t|
  #   t.integer  "user_id",                                                          null: false
  #   t.integer  "inst_book_id",                                                     null: false
  #   t.integer  "inst_section_id",                                                  null: false
  #   t.integer  "inst_book_section_exercise_id",                                    null: false
  #   t.boolean  "worth_credit",                                                          null: false
  #   t.datetime "time_done",                                                        null: false
  #   t.integer  "time_taken",                                                       null: false
  #   t.integer  "count_hints",                                                      null: false
  #   t.boolean  "hint_used",                                                        null: false
  #   t.decimal  "points_earned",                            precision: 5, scale: 2, null: false
  #   t.boolean  "earned_proficiency",                                               null: false
  #   t.integer  "count_attempts",                limit: 8,                          null: false
  #   t.string   "ip_address",                    limit: 20,                         null: false
  #   t.string   "question_name",                 limit: 50,                         null: false
  #   t.string   "request_type",                  limit: 50
  #   t.datetime "created_at"
  #   t.datetime "updated_at"
  # end

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
      inst_exercise = InstExercise.find_by(id: inst_book_section_exercise.inst_exercise_id)
      exercise_progress = self.get_exercise_progress
      book_progress = self.get_book_progress

      exercise_progress.first_done ||= DateTime.now
      exercise_progress.last_done = DateTime.now

      first_response = (self.count_attempts == 1 and self.count_hints == 0) ||
                       (self.count_attempts == 0 and self.count_hints == 1)


      book_progress.update_started(inst_exercise)

      if self.correct
        exercise_progress['total_correct'] += 1
        if self.worth_credit
          exercise_progress['total_worth_credit'] += 1
          exercise_progress['current_score'] += 1
          exercise_progress['highest_score'] = [exercise_progress['highest_score'], exercise_progress['current_score']].max

          book_progress.update_proficiency(exercise_progress)

          if exercise_progress['correct_exercises'].to_s.strip.length == 0
            exercise_progress['correct_exercises'] = self['question_name']
          else
            exercise_progress['correct_exercises'] += ',' + self['question_name']
          end
        else
          # progress thing goes here
        end

        # when student answer an exercise correctly from first time then clear the hint
        if self.request_type != 'hint'
          exercise_progress['hinted_exercise'] = ""
        end
      else
        if self.count_hints == 0 and self.request_type != 'hint' and self.count_attempts == 1
          # Only count wrong answer at most once per problem
          if exercise_progress['current_score'] - 1 > 0
            exercise_progress['current_score'] -= 1
          else
            exercise_progress['current_score'] = 0
          end
        end

        # progress thing goes here
        # if first_response
        #   exercise_progress['earned_proficiency'] = false
        # end
      end

      # save exercise_name to hinted_exercise so that student won't get credit if he saw the hint then refreshes the page
      if self.request_type == 'hint' and inst_exercise.short_name.include? "Summ"
        exercise_progress['hinted_exercise'] = self['question_name']
      end

      exercise_progress.save
  end

  def get_exercise_progress
    return OdsaExerciseProgress.where("user_id=? and inst_book_section_exercise_id=?",
                                                 user.id,
                                                 inst_book_section_exercise.id).first
  end

  def get_book_progress
    unless book_progress = OdsaBookProgress.where("user_id=? and inst_book_id=?",
                                                 user.id, inst_book.id).first
      book_progress = OdsaBookProgress.new(
        user: user,
                                           inst_book: inst_book)
    end
    book_progress.save
  end


  #~ Private instance methods .................................................

 end
