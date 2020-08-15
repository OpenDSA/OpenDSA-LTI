class AddIndexToOdsaExerciseProgresses < ActiveRecord::Migration[5.1]
  def change
    add_index :odsa_exercise_progresses, [:user_id, :inst_course_offering_exercise_id], unique: true,
    name: 'index_odsa_exercise_prog_on_user_course_offering_exercise'
  end
end
