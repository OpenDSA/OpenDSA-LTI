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
class PiAttempt < ApplicationRecord
end
