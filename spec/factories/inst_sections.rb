# == Schema Information
#
# Table name: inst_sections
#
#  id                     :integer          not null, primary key
#  inst_module_id         :integer          not null
#  inst_chapter_module_id :integer          not null
#  short_display_name     :string(50)
#  name                   :string(255)      not null
#  position               :integer
#  gradable               :boolean          default(FALSE)
#  soft_deadline          :datetime
#  hard_deadline          :datetime
#  time_limit             :integer
#  show                   :boolean          default(TRUE)
#  lms_item_id            :integer
#  lms_assignment_id      :integer
#  created_at             :datetime
#  updated_at             :datetime
#  learning_tool          :string(255)
#  resource_type          :string(255)
#  resource_name          :string(255)
#  lms_posted             :boolean
#  time_posted            :datetime
#
# Indexes
#
#  inst_sections_inst_chapter_module_id_fk  (inst_chapter_module_id)
#  inst_sections_inst_module_id_fk          (inst_module_id)
#

FactoryBot.define do
  factory :inst_section do
  end
end
