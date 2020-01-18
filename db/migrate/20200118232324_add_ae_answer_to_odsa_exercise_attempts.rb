class AddAeAnswerToOdsaExerciseAttempts < ActiveRecord::Migration
  def change
    add_column :odsa_exercise_attempts, :answer, :string
  end
end
