# == Schema Information
#
# Table name: organizations
#
#  id           :integer          not null, primary key
#  name         :string(255)      default(""), not null
#  created_at   :datetime
#  updated_at   :datetime
#  abbreviation :string(255)
#  slug         :string(255)      default(""), not null
#
# Indexes
#
#  index_organizations_on_slug  (slug) UNIQUE
#

FactoryBot.define do

  factory :learning_tool do
    name "code-workout"
    key "canvas_key"
    secret "canvas_secret"
    launch_url "  https://192.168.33.10:9200/lti/launch"
  end

end
