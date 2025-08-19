# == Schema Information
#
# Table name: odsa_exercise_attempts
#
#  id                               :bigint           not null, primary key
#  user_id                          :bigint           not null
#  inst_book_id                     :bigint
#  inst_section_id                  :bigint
#  inst_book_section_exercise_id    :bigint
#  worth_credit                     :boolean          not null
#  time_done                        :datetime         not null
#  time_taken                       :bigint           not null
#  count_hints                      :bigint           not null
#  hint_used                        :boolean          not null
#  points_earned                    :decimal(5, 2)    not null
#  earned_proficiency               :boolean          not null
#  count_attempts                   :bigint           not null
#  ip_address                       :string(20)       not null
#  question_name                    :string(50)       not null
#  request_type                     :string(50)
#  created_at                       :datetime
#  updated_at                       :datetime
#  correct                          :boolean
#  pe_score                         :decimal(5, 2)
#  pe_steps_fixed                   :bigint
#  inst_course_offering_exercise_id :bigint
#  inst_module_section_exercise_id  :bigint
#  answer                           :string(255)
#  question_id                      :integer
#
# Indexes
#
#  fk_rails_6944f2321b                                         (inst_module_section_exercise_id)
#  odsa_exercise_attempts_inst_book_id_fk                      (inst_book_id)
#  odsa_exercise_attempts_inst_book_section_exercise_id_fk     (inst_book_section_exercise_id)
#  odsa_exercise_attempts_inst_course_offering_exercise_id_fk  (inst_course_offering_exercise_id)
#  odsa_exercise_attempts_inst_section_id_fk                   (inst_section_id)
#  odsa_exercise_attempts_user_id_fk                           (user_id)
#

class OdsaExerciseAttempt < ApplicationRecord
  #~ Relationships ............................................................
  belongs_to :user
  belongs_to :inst_book
  belongs_to :inst_section
  belongs_to :inst_book_section_exercise
  belongs_to :inst_course_offering_exercise
  belongs_to :inst_module_section_exercise

  #~ Validation ...............................................................
  validate :required_fields

  def required_fields
    if !(inst_book_section_exercise_id.present? or inst_course_offering_exercise_id.present? or inst_module_section_exercise_id.present?)
      errors.add(:base, "inst_book_section_exercise_id or inst_course_offering_exercise_id or inst_module_section_exercise_id must be present")
    end
  end

  #~ Constants ................................................................
  #~ Hooks ....................................................................
  after_create :update_exercise_progress
  #~ Class methods ............................................................
  #~ Instance methods .........................................................
  def update_exercise_progress
    hasBook = !inst_book_section_exercise_id.blank?

    if hasBook
      @inst_chapter_module = inst_book_section_exercise.get_chapter_module
      if @inst_chapter_module.due_dates.nil? or @inst_chapter_module.due_dates > Time.now
        if self.request_type === 'PE'
          update_pe_exercise_progress
        elsif self.request_type === 'AE'
          update_ae_exercise_progress
        elsif self.request_type === 'PI'
          update_pi_exercise_progress
        else
          update_ka_exercise_progress
        end
      end
    else
      if self.request_type === 'PE'
        update_pe_exercise_progress
      elsif self.request_type === 'AE'
        update_ae_exercise_progress
      elsif self.request_type === 'PI'
        update_pi_exercise_progress
      else
        update_ka_exercise_progress
      end
    end
  end

  def update_ka_exercise_progress
    hasBook = !inst_book_section_exercise_id.blank?
    has_standalone_module = !inst_module_section_exercise_id.blank?

    if hasBook
      @inst_chapter_module = inst_book_section_exercise.get_chapter_module
      inst_exercise = InstExercise.find_by(id: inst_book_section_exercise.inst_exercise_id)
      book_progress = OdsaBookProgress.get_progress(user_id, inst_book_id)
      module_progress = OdsaModuleProgress.get_progress(user_id, @inst_chapter_module.id, inst_book_id)
    elsif has_standalone_module
      inst_exercise = InstExercise.find_by(id: inst_module_section_exercise.inst_exercise)
      module_progress = OdsaModuleProgress.get_standalone_progress(user_id, inst_module_section_exercise.inst_module_version_id)
    else
      inst_exercise = InstExercise.find_by(id: inst_course_offering_exercise.inst_exercise_id)
    end
    exercise_progress = self.get_exercise_progress
    exercise_progress.first_done ||= DateTime.now
    exercise_progress.last_done = DateTime.now
    # first_response = (self.count_attempts == 1 and self.count_hints == 0) ||
    #                  (self.count_attempts == 0 and self.count_hints == 1)

    if hasBook
      book_progress.update_started(inst_exercise)
    end
    proficient = false
    if self.correct
      exercise_progress['total_correct'] += 1
      if self.worth_credit
        exercise_progress['total_worth_credit'] += 1
        exercise_progress['current_score'] += 1
        exercise_progress['highest_score'] = [exercise_progress['highest_score'], exercise_progress['current_score']].max
        proficient = false
        if hasBook
          proficient = book_progress.update_proficiency(exercise_progress)
        elsif has_standalone_module
          proficient = exercise_progress.highest_score >= inst_module_section_exercise.threshold
        else
          proficient = exercise_progress.highest_score >= inst_course_offering_exercise.threshold
        end
        if proficient
          self.earned_proficiency = true
          if hasBook
            self.points_earned = inst_book_section_exercise.points
          elsif has_standalone_module
            self.points_earned = inst_module_section_exercise.points
          else
            self.points_earned = inst_course_offering_exercise.points
          end
          self.save!
          exercise_progress.proficient_date ||= DateTime.now
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
    exercise_progress.save!
    if proficient
      if hasBook
        module_progress.update_proficiency(inst_exercise)
      elsif has_standalone_module
        module_progress.update_proficiency(inst_module_section_exercise)
      end
    end
  end

  def update_pe_exercise_progress
    hasBook = !inst_book_section_exercise_id.blank?
    has_standalone_module = !inst_module_section_exercise_id.blank?
    if hasBook
      @inst_chapter_module = inst_book_section_exercise.get_chapter_module
      inst_exercise = InstExercise.find_by(id: inst_book_section_exercise.inst_exercise_id)
      book_progress = OdsaBookProgress.get_progress(user_id, inst_book_id)
      module_progress = OdsaModuleProgress.get_progress(user_id, @inst_chapter_module.id, inst_book_id)
    elsif has_standalone_module
      inst_exercise = InstExercise.find(inst_module_section_exercise.inst_exercise_id)
      module_progress = OdsaModuleProgress.get_standalone_progress(user_id, inst_module_section_exercise.inst_module_version_id)
    else
      inst_exercise = InstExercise.find(inst_course_offering_exercise.inst_exercise_id)
    end
    exercise_progress = self.get_exercise_progress
    exercise_progress.first_done ||= DateTime.now
    exercise_progress.last_done = DateTime.now
    if hasBook
      book_progress.update_started(inst_exercise)
    end
    if self.correct
      self.earned_proficiency = true
      if hasBook
        self.points_earned = inst_book_section_exercise.points
        Rails.logger.info(inst_book_section_exercise.points)
      elsif has_standalone_module
        self.points_earned = inst_module_section_exercise.points
      else
        self.points_earned = inst_course_offering_exercise.points
      end
      self.save!
      exercise_progress['total_correct'] += 1
      exercise_progress['total_worth_credit'] += 1
      exercise_progress['current_score'] = self.points_earned
      exercise_progress['highest_score'] = self.points_earned
      exercise_progress.proficient_date ||= DateTime.now
      exercise_progress.save!
      if hasBook
        module_progress.update_proficiency(inst_exercise)
        book_progress.update_proficiency(exercise_progress)
      elsif has_standalone_module
        module_progress.update_proficiency(inst_module_section_exercise)
      end
    else
      exercise_progress.save!
    end
  end

  def update_ae_exercise_progress
    hasBook = !inst_book_section_exercise_id.blank?
    has_standalone_module = !inst_module_section_exercise_id.blank?
    if hasBook
      @inst_chapter_module = inst_book_section_exercise.get_chapter_module
      inst_exercise = InstExercise.find_by(id: inst_book_section_exercise.inst_exercise_id)
      book_progress = OdsaBookProgress.get_progress(user_id, inst_book_id)
      module_progress = OdsaModuleProgress.get_progress(user_id, @inst_chapter_module.id, inst_book_id)
    elsif has_standalone_module
      inst_exercise = InstExercise.find(inst_module_section_exercise.inst_exercise_id)
      module_progress = OdsaModuleProgress.get_standalone_progress(user_id, inst_module_section_exercise.inst_module_version_id)
    else
      inst_exercise = InstExercise.find(inst_course_offering_exercise.inst_exercise_id)
    end
    exercise_progress = self.get_exercise_progress
    exercise_progress.first_done ||= DateTime.now
    exercise_progress.last_done = DateTime.now
    if hasBook
      book_progress.update_started(inst_exercise)
    end
    if self.correct
      self.earned_proficiency = true
      if hasBook
        if self.request_type == 'AE'
          self.points_earned = inst_book_section_exercise.points * self.pe_score
        else
          self.points_earned = inst_book_section_exercise.points
        end
      elsif has_standalone_module
        self.points_earned = inst_module_section_exercise.points
      else
        self.points_earned = inst_course_offering_exercise.points
      end
      self.save!
      exercise_progress['total_correct'] += 1
      exercise_progress['total_worth_credit'] += 1
      exercise_progress['current_score'] = self.points_earned
      exercise_progress['highest_score'] = self.points_earned
      exercise_progress.proficient_date ||= DateTime.now
      exercise_progress.save!
      if hasBook
        module_progress.update_proficiency(inst_exercise)
        book_progress.update_proficiency(exercise_progress)
      elsif has_standalone_module
        module_progress.update_proficiency(inst_module_section_exercise)
      end
    else
      exercise_progress.save!
    end
  end

  def update_pi_exercise_progress
    Rails.logger.info("update_pi_exercise_progress")
    hasBook = !inst_book_section_exercise_id.blank?
    has_standalone_module = !inst_module_section_exercise_id.blank?
    if hasBook
      Rails.logger.info("update_pi_exercise_progress -> hasBook")
      @inst_chapter_module = inst_book_section_exercise.get_chapter_module
      inst_exercise = InstExercise.find_by(id: inst_book_section_exercise.inst_exercise_id)
      book_progress = OdsaBookProgress.get_progress(user_id, inst_book_id)
      module_progress = OdsaModuleProgress.get_progress(user_id, @inst_chapter_module.id, inst_book_id)
    elsif has_standalone_module
      inst_exercise = InstExercise.find(inst_module_section_exercise.inst_exercise_id)
      module_progress = OdsaModuleProgress.get_standalone_progress(user_id, inst_module_section_exercise.inst_module_version_id)
    else
      inst_exercise = InstExercise.find(inst_course_offering_exercise.inst_exercise_id)
    end
    exercise_progress = self.get_exercise_progress
    exercise_progress.first_done ||= DateTime.now
    exercise_progress.last_done = DateTime.now
    if hasBook
      Rails.logger.info("update_pi_exercise_progress -> hasBook 2222")
      book_progress.update_started(inst_exercise)
    end
    if self.correct and self.finished_frame
      self.earned_proficiency = true
      if hasBook
        self.points_earned = inst_book_section_exercise.points
        Rails.logger.info(inst_book_section_exercise.points)
      elsif has_standalone_module
        self.points_earned = inst_module_section_exercise.points
      else
        self.points_earned = inst_course_offering_exercise.points
      end
      self.save!
      exercise_progress['total_correct'] += 1
      exercise_progress['total_worth_credit'] += 1
      exercise_progress['current_score'] = self.points_earned
      exercise_progress['highest_score'] = self.points_earned
      exercise_progress.proficient_date ||= DateTime.now
      exercise_progress.save!
      if hasBook
        Rails.logger.info("update_pi_exercise_progress -> update_module_progress_procifiency")
        module_progress.update_proficiency(inst_exercise)
        Rails.logger.info("update_pi_exercise_progress -> update_book_progress_procifiency")
        book_progress.update_proficiency(exercise_progress)
      elsif has_standalone_module
        module_progress.update_proficiency(inst_module_section_exercise)
      end
    else
      exercise_progress.save!
    end
  end

  def get_exercise_progress
    if !inst_book_section_exercise_id.blank?
      return OdsaExerciseProgress.where("user_id=? and inst_book_section_exercise_id=?",
        user.id,
        inst_book_section_exercise.id).first
    elsif !inst_module_section_exercise_id.blank?
      return OdsaExerciseProgress.find_by(user_id: user_id,
        inst_module_section_exercise_id: inst_module_section_exercise_id)
    else
      return OdsaExerciseProgress.find_by(user_id: user_id,
        inst_course_offering_exercise_id: inst_course_offering_exercise_id)
    end
  end

  #~ Private instance methods .................................................

end
