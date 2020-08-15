class AddPeStepsFixedToOdsaExerciseAttempts < ActiveRecord::Migration[5.1]
  def change
    add_column :odsa_exercise_attempts, :pe_steps_fixed, :integer
  end
end
