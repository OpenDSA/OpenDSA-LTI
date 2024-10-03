# == Schema Information
#
# Table name: organizations
#
#  id           :integer          not null, primary key
#  name         :string(255)      not null
#  created_at   :datetime
#  updated_at   :datetime
#  abbreviation :string(255)
#  slug         :string(255)      not null
#
# Indexes
#
#  index_organizations_on_name  (name) UNIQUE
#  index_organizations_on_slug  (slug) UNIQUE
#

FactoryBot.define do

  factory :organization do
    name { "Virginia Tech" }
    abbreviation { "VT" }
  end

end
