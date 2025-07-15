# == Schema Information
#
# Table name: inst_chapter_modules
#
#  id                  :bigint           not null, primary key
#  inst_chapter_id     :bigint           not null
#  inst_module_id      :bigint           not null
#  module_position     :bigint
#  lms_module_item_id  :bigint
#  lms_section_item_id :bigint
#  created_at          :datetime
#  updated_at          :datetime
#  lms_assignment_id   :bigint
#
# Indexes
#
#  inst_chapter_modules_inst_chapter_id_fk  (inst_chapter_id)
#  inst_chapter_modules_inst_module_id_fk   (inst_module_id)
#
class InstChapterModule < ApplicationRecord
  #~ Relationships ............................................................
  belongs_to :inst_chapter
  belongs_to :inst_module
  has_many :inst_sections, dependent: :destroy
  has_many :odsa_module_progresses, inverse_of: :inst_chapter_module, dependent: :destroy
  has_many :odsa_user_interactions, dependent: :destroy
  has_many :student_extensions, inverse_of: :inst_chapter_module, dependent: :destroy

  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  #~ Instance methods .........................................................

  # --------------------------------------------------------------------------
  # clone inst_chapter_module
  def clone(book, chapter)
    ch_mod = InstChapterModule.new
    ch_mod.inst_chapter_id = chapter.id
    ch_mod.inst_module_id = self.inst_module_id
    ch_mod.module_position = self.module_position
    ch_mod.save

    inst_sections.each do |section|
      inst_section = section.clone(book, ch_mod)
    end
  end

  # --------------------------------------------------------------------------
  # gets all the exercises in one module
  def get_exercises_list
    exercises_list = []
    inst_sections.each do |inst_section|
      exercises_ids = inst_section.inst_book_section_exercises.collect(&:inst_exercise_id).compact
      exercises_objs = InstExercise.where(id: exercises_ids)
      exercises_list.concat exercises_objs.collect(&:short_name)
    end
    return exercises_list
  end

  # get all of the inst_book_section_exercise instances associated with this module
  def get_bk_sec_exercises()
    InstBookSectionExercise.includes(:inst_exercise)
      .joins(:inst_section)
      .where(inst_sections: {inst_chapter_module_id: self.id})
  end

  # get all exercise progresses for the exercises in this module for the specified user
  def get_exercise_progresses(user_id)
    OdsaExerciseProgress.joins(inst_book_section_exercise: [:inst_section])
      .where(inst_sections: {inst_chapter_module_id: self.id}, user_id: user_id)
  end

  def gradable?
    InstSection.where(inst_chapter_module_id: self.id, gradable: true).exists?
  end

  def total_points
    return InstBookSectionExercise.joins(inst_section: [:inst_chapter_module])
             .where(inst_sections: {inst_chapter_module_id: self.id}).sum(:points)
  end

  # -------------------------------------------------------------
  # Get the effective deadline for a specific user, considering extensions
  def effective_deadline(user)
    extension = student_extensions.find_by(user: user)
    if extension&.due_deadline
      extension.due_deadline
    else
      due_dates
    end
  end

  # -------------------------------------------------------------
  # Check if the module is still open for a specific user
  def open_for_user?(user)
    effective_open = effective_open_date(user)
    effective_open.nil? || effective_open <= Time.now
  end

  # -------------------------------------------------------------
  # Check if the module is past due for a specific user
  def past_due_for_user?(user)
    effective_due = effective_deadline(user)
    effective_due && effective_due < Time.now
  end

  # -------------------------------------------------------------
  # Check if the module is closed for a specific user
  def closed_for_user?(user)
    effective_close = effective_close_date(user)
    effective_close && effective_close < Time.now
  end

  # -------------------------------------------------------------
  # Check if a user can still submit to this module
  def can_submit_for_user?(user)
    # Module must be open and not closed
    open_for_user?(user) && !closed_for_user?(user)
  end

  # -------------------------------------------------------------
  # Get time remaining for a user (in seconds)
  def time_remaining_for_user(user)
    effective_close = effective_close_date(user)
    return nil unless effective_close
    
    remaining = effective_close - Time.now
    remaining > 0 ? remaining.to_i : 0
  end

  # -------------------------------------------------------------
  # Get the effective open date for a specific user
  def effective_open_date(user)
    extension = student_extensions.find_by(user: user)
    if extension&.open_deadline
      extension.open_deadline
    else
      # You might want to add an open_dates field to inst_chapter_modules
      # For now, return nil (always open)
      nil
    end
  end

  # -------------------------------------------------------------
  # Get the effective close date for a specific user
  def effective_close_date(user)
    extension = student_extensions.find_by(user: user)
    if extension&.close_deadline
      extension.close_deadline
    else
      # You might want to add a close_dates field to inst_chapter_modules
      # For now, return nil (never close)
      nil
    end
  end

  #~ Private instance methods .................................................
end
