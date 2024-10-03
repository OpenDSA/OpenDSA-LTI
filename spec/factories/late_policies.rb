# == Schema Information
#
# Table name: late_policies
#
#  id           :integer          not null, primary key
#  name         :string(255)      not null
#  late_days    :integer          not null
#  late_percent :integer          not null
#  created_at   :datetime
#  updated_at   :datetime
#
# Indexes
#
#  index_late_policies_on_name  (name) UNIQUE
#

FactoryBot.define do
  factory :late_policy do
    name { "late_10" }
  end
end
