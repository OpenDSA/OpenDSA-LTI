class AddColumnsToExerciseAttempts < ActiveRecord::Migration[6.0]
  def change
    add_column :odsa_exercise_attempts, :question_id, :integer
  end
end
