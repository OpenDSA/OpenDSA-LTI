# == Schema Information
#
# Table name: pi_attempts
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  frame_name :string(255)
#  question   :integer
#  correct    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :pi_attempt do
    user_id { 1 }
    frame_name { "" }
    question { "" }
    correct { 1 }
  end
end
