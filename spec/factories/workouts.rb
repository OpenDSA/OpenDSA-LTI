# == Schema Information
#
# Table name: workouts
#
#  id                :integer          not null, primary key
#  name              :string(255)      default(""), not null
#  scrambled         :boolean          default(FALSE)
#  created_at        :datetime
#  updated_at        :datetime
#  description       :text
#  points_multiplier :integer
#  creator_id        :integer
#  external_id       :string(255)
#  is_public         :boolean
#
# Indexes
#
#  index_workouts_on_external_id  (external_id) UNIQUE
#  index_workouts_on_is_public    (is_public)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :workout do
    name { 'Workout from Factory' }
    scrambled { true }
    description { 'Created by Factory Girl for testing.' }
    language_list { 'Java' }
    tag_list { 'factorial, function, multiplication' }
    style_list { 'code writing' }

    factory :workout_with_exercises do
      after :create do |w|
        FactoryBot.create :exercise_workout,
          workout_id: w.id,
          exercise: FactoryBot.create(:coding_exercise)
        FactoryBot.create :exercise_workout,
          workout_id: w.id,
          exercise: FactoryBot.create(:mc_exercise)
        FactoryBot.create :exercise_workout,
          workout_id: w.id,
          exercise: FactoryBot.create(:coding_exercise)
      end
    end
  end
end
