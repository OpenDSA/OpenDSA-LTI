# == Schema Information
#
# Table name: odsa_user_time_tracking_stagings
#
#  id              :bigint           not null, primary key
#  user_id         :bigint           not null
#  inst_book_id    :bigint
#  inst_module_id  :bigint
#  inst_chapter_id :bigint
#  uuid            :string(50)       not null
#  session_date    :string(50)       not null
#  total_time      :decimal(10, 2)   not null
#  sections_time   :text(65535)      not null
#  created_at      :datetime
#  updated_at      :datetime
#
class OdsaUserTimeTrackingStaging < ApplicationRecord
  belongs_to :user
  belongs_to :inst_book, optional: true
  belongs_to :inst_module, optional: true
  belongs_to :inst_chapter, optional: true

  validate :required_fields

  def required_fields
    return if inst_book_id.present?

    errors.add(:base, "inst_book_id must be present")
  end
end
