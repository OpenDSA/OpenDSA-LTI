class AddAeAnswerToOdsaExerciseAttempts < ActiveRecord::Migration[5.1]
  def change
    add_column :odsa_exercise_attempts, :answer, :string
  end
end
