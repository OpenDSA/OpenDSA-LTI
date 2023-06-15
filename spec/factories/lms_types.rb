# == Schema Information
#
# Table name: lms_types
#
#  id         :bigint           not null, primary key
#  name       :string(255)      not null
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_lms_types_on_name  (name) UNIQUE
#

FactoryBot.define do
  factory :lms_type do
  end
end
