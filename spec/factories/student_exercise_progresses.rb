FactoryBot.define do
  factory :student_exercise_progress do
    userId { "" }
    exerciseId { "" }
    progress { "MyText" }
    grade { "9.99" }
  end
end
