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

FactoryBot.define do
  factory :inst_chapter_module do
  end
end
