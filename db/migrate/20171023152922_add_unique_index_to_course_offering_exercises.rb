class AddUniqueIndexToCourseOfferingExercises < ActiveRecord::Migration[5.1]
  def change
    add_index :inst_course_offering_exercises, [:course_offering_id, :resource_link_id], 
      unique: true, name: 'index_inst_course_offering_exercises_on_course_offering_resource'
  end
end
