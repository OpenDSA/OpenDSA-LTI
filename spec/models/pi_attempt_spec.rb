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
require 'rails_helper'

RSpec.describe PiAttempt, type: :model do
  it "creates a new PI_Attempts object" do
    expect {
      PiAttempt.find_or_create(user_id: 5, frame_name: "Test", question: 3, correct: 0)
    }.to change{PiAttempt.count}.by(1)
  end
end
