# == Schema Information
#
# Table name: inst_chapter_modules
#
#  id                  :integer          not null, primary key
#  inst_chapter_id     :integer          not null
#  inst_module_id      :integer          not null
#  module_position     :integer
#  lms_module_item_id  :integer
#  lms_section_item_id :integer
#  created_at          :datetime
#  updated_at          :datetime
#  lms_assignment_id   :integer
#  due_date           :datetime
#  open_date           :datetime
#  close_date          :datetime
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
  has_many :student_extensions, dependent: :destroy
  has_many :users, through: :student_extensions

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

  def get_due_date_for(user_id)
    extension = StudentExtension.where(inst_chapter_module_id: self.id, user_id: user_id).first
    if extension.nil? || extension.due_date.nil?
      return self.due_date
    end
    return [extension.due_date, self.due_date].min
  end

  def get_close_date_for(user_id)
    extension = StudentExtension.where(inst_chapter_module_id: self.id, user_id: user_id).first
    if extension.nil? || extension.close_date.nil?
      return self.close_date
    end
    return [extension.close_date, self.close_date].min
  end

  def get_open_date_for(user_id)
    extension = StudentExtension.where(inst_chapter_module_id: self.id, user_id: user_id).first
    if extension.nil? || extension.open_date.nil?
      return self.open_date
    end
    return [extension.open_date, self.open_date].min
  end

  def gradable?
    InstSection.where(inst_chapter_module_id: self.id, gradable: true).exists?
  end

  def total_points
    return InstBookSectionExercise.joins(inst_section: [:inst_chapter_module])
             .where(inst_sections: {inst_chapter_module_id: self.id}).sum(:points)
  end

  #~ Private instance methods .................................................
end
