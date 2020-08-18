class AddThresholdToInstCourseOfferingExercises < ActiveRecord::Migration[5.1]
  def change
    add_column :inst_course_offering_exercises, :threshold, :decimal, precision: 5, scale: 2, null: false
  end
end
