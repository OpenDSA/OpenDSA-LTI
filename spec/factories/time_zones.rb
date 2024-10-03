# == Schema Information
#
# Table name: time_zones
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  zone       :string(255)
#  display_as :string(255)
#  created_at :datetime
#  updated_at :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :time_zone do
    name { "America/New_York" }
    zone { "UTC -05:00" }
    display_as { "UTC -05:00(New York)" }
  end
end
