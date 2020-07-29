class RemoveProgressFromOdsaExerciseProgresses < ActiveRecord::Migration[5.1]
  def change
    remove_column :odsa_exercise_progresses, :progress
  end
end
