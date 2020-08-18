class AddPeScoreToOdsaExerciseAttempts < ActiveRecord::Migration[5.1]
  def change
    add_column :odsa_exercise_attempts, :pe_score, :decimal, precision: 5, scale: 2
  end
end
