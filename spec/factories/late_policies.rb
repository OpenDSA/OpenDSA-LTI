# == Schema Information
#
# Table name: late_policies
#
#  id           :bigint           not null, primary key
#  name         :string(255)      not null
#  late_days    :bigint           not null
#  late_percent :bigint           not null
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
