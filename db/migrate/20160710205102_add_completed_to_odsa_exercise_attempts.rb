class AddCompletedToOdsaExerciseAttempts < ActiveRecord::Migration[5.1]
  def change
    add_column :odsa_exercise_attempts, :completed, :boolean
  end
end
