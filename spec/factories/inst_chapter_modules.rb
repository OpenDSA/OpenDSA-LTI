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
#  due_date            :datetime
#  open_date           :datetime
#  close_date          :datetime
#
# Indexes
#
#  inst_chapter_modules_inst_chapter_id_fk  (inst_chapter_id)
#  inst_chapter_modules_inst_module_id_fk   (inst_module_id)
#

FactoryBot.define do
  factory :inst_chapter_module do
  end
end
