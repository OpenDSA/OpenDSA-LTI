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
class PiAttempt < ApplicationRecord
end
