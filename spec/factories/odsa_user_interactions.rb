# == Schema Information
#
# Table name: odsa_user_interactions
#
#  id                               :bigint           not null, primary key
#  user_id                          :bigint           not null
#  inst_book_id                     :bigint
#  inst_section_id                  :bigint
#  inst_book_section_exercise_id    :bigint
#  name                             :string(50)       not null
#  description                      :text(4294967295) not null
#  action_time                      :datetime         not null
#  uiid                             :bigint           not null
#  browser_family                   :string(20)       not null
#  browser_version                  :string(20)       not null
#  os_family                        :string(50)       not null
#  os_version                       :string(20)       not null
#  device                           :string(50)       not null
#  ip_address                       :string(20)       not null
#  created_at                       :datetime
#  updated_at                       :datetime
#  inst_course_offering_exercise_id :bigint
#  inst_chapter_module_id           :bigint
#  inst_module_version_id           :bigint
#  inst_module_section_exercise_id  :bigint
#
# Indexes
#
#  fk_rails_599b647d17                                         (inst_module_version_id)
#  fk_rails_9d3d089a83                                         (inst_module_section_exercise_id)
#  index_odsa_user_interactions_on_inst_chapter_module         (inst_chapter_module_id)
#  odsa_user_interactions_inst_book_id_fk                      (inst_book_id)
#  odsa_user_interactions_inst_book_section_exercise_id_fk     (inst_book_section_exercise_id)
#  odsa_user_interactions_inst_course_offering_exercise_id_fk  (inst_course_offering_exercise_id)
#  odsa_user_interactions_inst_section_id_fk                   (inst_section_id)
#  odsa_user_interactions_user_id_fk                           (user_id)
#

FactoryBot.define do
  factory :odsa_user_interaction do
  end
end
