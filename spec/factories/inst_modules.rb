# == Schema Information
#
# Table name: inst_modules
#
#  id                 :bigint           not null, primary key
#  path               :string(255)      not null
#  name               :string(255)      not null
#  created_at         :datetime
#  updated_at         :datetime
#  current_version_id :bigint
#
# Indexes
#
#  fk_rails_73d3622e40         (current_version_id)
#  index_inst_modules_on_path  (path) UNIQUE
#

FactoryBot.define do
  factory :inst_module do
  end
end
