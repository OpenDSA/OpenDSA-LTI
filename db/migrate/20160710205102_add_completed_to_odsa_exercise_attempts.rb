class AddCompletedToOdsaExerciseAttempts < ActiveRecord::Migration
  def change
    add_column :odsa_exercise_attempts, :completed, :boolean
  end
end
