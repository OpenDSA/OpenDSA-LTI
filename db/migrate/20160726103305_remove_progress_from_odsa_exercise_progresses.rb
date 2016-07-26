class RemoveProgressFromOdsaExerciseProgresses < ActiveRecord::Migration
  def change
    remove_column :odsa_exercise_progresses, :progress
  end
end
