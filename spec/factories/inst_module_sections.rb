# == Schema Information
#
# Table name: inst_module_sections
#
#  id                     :bigint           not null, primary key
#  inst_module_version_id :bigint           not null
#  name                   :string(255)      not null
#  show                   :boolean          default(TRUE)
#  learning_tool          :string(255)
#  resource_type          :string(255)
#  resource_name          :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  fk_rails_ff11275e48  (inst_module_version_id)
#
FactoryBot.define do
  factory :inst_module_section do
    
  end
end
