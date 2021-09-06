# == Schema Information
#
# Table name: pi_attempts
#
#  id         :bigint           not null, primary key
#  user_id    :bigint
#  frame_name :string(255)
#  question   :bigint
#  correct    :bigint
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
