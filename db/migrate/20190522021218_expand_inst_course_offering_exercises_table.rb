class ExpandInstCourseOfferingExercisesTable < ActiveRecord::Migration[5.1]
  def change
    add_column :inst_course_offering_exercises, :points, :decimal, precision: 5, scale: 2, null: false
    add_column :inst_course_offering_exercises, :options, :text, limit: 2147483647

    change_column_null :inst_course_offering_exercises, :resource_link_id, true
    change_column_default :inst_course_offering_exercises, :resource_link_id, nil
    
    add_column :odsa_exercise_progresses, :lis_outcome_service_url, :string
    add_column :odsa_exercise_progresses, :lis_result_sourcedid, :string
    add_column :odsa_exercise_progresses, :lms_access_id, :integer
    add_foreign_key :odsa_exercise_progresses, :lms_accesses
  end
end
