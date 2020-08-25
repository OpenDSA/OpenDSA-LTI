class ModifyCourseExerciseIndex < ActiveRecord::Migration[5.1]
  def change

    remove_foreign_key :inst_course_offering_exercises, :course_offerings

    remove_index :inst_course_offering_exercises, name: 'index_inst_course_offering_exercises_on_course_offering_res'

    add_index :inst_course_offering_exercises, [:course_offering_id, :resource_link_id, :inst_exercise_id], 
      unique: true, name: 'index_inst_course_offering_exercises_on_course_offering_res'

    add_foreign_key :inst_course_offering_exercises, :course_offerings

  end
end
