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
  after_create :update_exercise_progress
  #~ Class methods ............................................................
  #~ Instance methods .........................................................
  def update_exercise_progress
    if self.request_type === 'PE'
      update_pe_exercise_progress
    else
      update_ka_exercise_progress
    end
  end

  def update_ka_exercise_progress
    @inst_chapter_module = inst_book_section_exercise.get_chapter_module
    inst_exercise = InstExercise.find_by(id: inst_book_section_exercise.inst_exercise_id)
    book_progress = self.get_book_progress
    module_progress = self.get_module_progress
    exercise_progress = self.get_exercise_progress
    exercise_progress.first_done ||= DateTime.now
    exercise_progress.last_done = DateTime.now
    # first_response = (self.count_attempts == 1 and self.count_hints == 0) ||
    #                  (self.count_attempts == 0 and self.count_hints == 1)

    book_progress.update_started(inst_exercise)
    if self.correct
      exercise_progress['total_correct'] += 1
      if self.worth_credit
        exercise_progress['total_worth_credit'] += 1
        exercise_progress['current_score'] += 1
        exercise_progress['highest_score'] = [exercise_progress['highest_score'], exercise_progress['current_score']].max
        proficient = book_progress.update_proficiency(exercise_progress)
        if proficient
          self.earned_proficiency = true
          self.points_earned = inst_book_section_exercise.points
          self.save!
          exercise_progress.proficient_date ||= DateTime.now
          module_progress.update_proficiency(inst_exercise)
        end
        if exercise_progress['correct_exercises'].to_s.strip.length == 0
          exercise_progress['correct_exercises'] = self['question_name']
        else
          exercise_progress['correct_exercises'] += ',' + self['question_name']
        end
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
    end
    # save exercise_name to hinted_exercise so that student won't get credit if he saw the hint then refreshes the page
    if self.request_type == 'hint' and inst_exercise.short_name.include? "Summ"
      exercise_progress['hinted_exercise'] = self['question_name']
    end
    exercise_progress.save
  end

  def update_pe_exercise_progress
    @inst_chapter_module = inst_book_section_exercise.get_chapter_module
    inst_exercise = InstExercise.find_by(id: inst_book_section_exercise.inst_exercise_id)
    book_progress = self.get_book_progress
    module_progress = self.get_module_progress
    exercise_progress = self.get_exercise_progress
    exercise_progress.first_done ||= DateTime.now
    exercise_progress.last_done = DateTime.now

    book_progress.update_started(inst_exercise)
    if self.correct
      exercise_progress['total_correct'] += 1
      exercise_progress['total_worth_credit'] += 1
      exercise_progress['current_score'] = self.points_earned
      exercise_progress['highest_score'] = self.points_earned
      proficient = book_progress.update_proficiency(exercise_progress)
      if proficient
        self.earned_proficiency = true
        self.points_earned = inst_book_section_exercise.points
        self.save!
        exercise_progress.proficient_date ||= DateTime.now
        module_progress.update_proficiency(inst_exercise)
      end
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
      book_progress = OdsaBookProgress.create(user: user,inst_book: inst_book)
    end
    book_progress
  end

  def get_module_progress
    unless module_progress = OdsaModuleProgress.where(user: user,inst_book: inst_book,inst_chapter_module: @inst_chapter_module).first
      module_progress = OdsaModuleProgress.create(user: user,inst_book: inst_book,inst_chapter_module: @inst_chapter_module)
    end
    module_progress
  end


  #~ Private instance methods .................................................

 end
