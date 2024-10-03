# == Schema Information
#
# Table name: inst_module_versions
#
#  id                  :integer          not null, primary key
#  inst_module_id      :integer          not null
#  name                :string(255)      not null
#  git_hash            :string(255)      not null
#  file_path           :string(4096)     not null
#  template            :boolean          default(FALSE)
#  course_offering_id  :integer
#  resource_link_id    :string(255)
#  resource_link_title :string(512)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  fk_rails_7e343b3134                            (inst_module_id)
#  index_inst_module_versions_on_course_resource  (course_offering_id,resource_link_id) UNIQUE
#
FactoryBot.define do
  factory :inst_module_version do
    
  end
end
