class AddFinishedFrameToOdsaExerciseAttempt < ActiveRecord::Migration[6.0]
  def change
    add_column :odsa_exercise_attempts, :finished_frame, :boolean
  end
end
