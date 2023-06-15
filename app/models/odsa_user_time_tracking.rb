# == Schema Information
#
# Table name: odsa_user_time_trackings
#
#  id                               :bigint           not null, primary key
#  user_id                          :bigint           not null
#  inst_book_id                     :bigint
#  inst_section_id                  :bigint
#  inst_book_section_exercise_id    :bigint
#  inst_course_offering_exercise_id :bigint
#  inst_module_id                   :bigint
#  inst_chapter_id                  :bigint
#  inst_module_version_id           :bigint
#  inst_module_section_exercise_id  :bigint
#  uuid                             :string(50)       not null
#  session_date                     :string(50)       not null
#  total_time                       :decimal(10, 2)   not null
#  sections_time                    :text(65535)      not null
#  created_at                       :datetime
#  updated_at                       :datetime
#
# Indexes
#
#  index_odsa_user_time_trackings_on_inst_book_id_session_date  (inst_book_id,session_date)
#  index_odsa_user_time_trackings_on_user_id_uuid               (user_id,uuid) UNIQUE
#  odsa_user_time_tracking_inst_book_section_exercise_id_fk     (inst_book_section_exercise_id)
#  odsa_user_time_tracking_inst_chapter_id_fk                   (inst_chapter_id)
#  odsa_user_time_tracking_inst_course_offering_exercise_id_fk  (inst_course_offering_exercise_id)
#  odsa_user_time_tracking_inst_module_id_fk                    (inst_module_id)
#  odsa_user_time_tracking_inst_module_section_exercise_id_fk   (inst_module_section_exercise_id)
#  odsa_user_time_tracking_inst_module_version_id_fk            (inst_module_version_id)
#  odsa_user_time_tracking_inst_section_id_fk                   (inst_section_id)
#
class OdsaUserTimeTracking < ApplicationRecord
  #~ Relationships ............................................................
  belongs_to :user
  belongs_to :inst_book
  belongs_to :inst_book_section_exercise
  belongs_to :inst_course_offering_exercise
  belongs_to :inst_module
  belongs_to :inst_chapter
  belongs_to :inst_module_version
  belongs_to :inst_module_section_exercise

  #~ Validation ...............................................................
  validate :required_fields

  def required_fields
    if not(inst_book_id.present? or inst_course_offering_exercise_id.present? or inst_module_version_id.present?)
      errors.add(:base, "inst_book_id or inst_course_offering_exercise_id or inst_module_version_id must be present")
    end
  end

  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  #~ Instance methods .........................................................
  #~ Private instance methods .................................................
end
