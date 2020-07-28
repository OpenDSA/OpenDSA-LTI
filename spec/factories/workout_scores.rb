# == Schema Information
#
# Table name: workout_scores
#
#  id                  :integer          not null, primary key
#  workout_id          :integer          not null
#  user_id             :integer          not null
#  score               :float(24)
#  completed           :boolean
#  completed_at        :datetime
#  last_attempted_at   :datetime
#  exercises_completed :integer
#  exercises_remaining :integer
#  created_at          :datetime
#  updated_at          :datetime
#  workout_offering_id :integer
#
# Indexes
#
#  index_workout_scores_on_user_id     (user_id)
#  index_workout_scores_on_workout_id  (workout_id)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :workout_score do
    score { "" }
    completed { false }
    started_at { "2015-01-17 14:08:55" }
    completed_at { "2015-01-17 14:08:55" }
    last_attempted_at { "2015-01-17 14:08:55" }
    exercises_completed { 1 }
    exercises_remaining { 1 }
  end
end
