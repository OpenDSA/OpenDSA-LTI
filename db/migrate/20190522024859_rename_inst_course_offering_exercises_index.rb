class RenameInstCourseOfferingExercisesIndex < ActiveRecord::Migration
  def change
    rename_index :inst_course_offering_exercises, 
    'index_inst_course_offering_exercises_on_course_offering_resource', 
    'index_inst_course_offering_exercises_on_course_offering_res'
  end
end
