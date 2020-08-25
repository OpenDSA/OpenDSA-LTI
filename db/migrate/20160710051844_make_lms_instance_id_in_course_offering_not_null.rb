class MakeLmsInstanceIdInCourseOfferingNotNull < ActiveRecord::Migration[5.1]
  def change
    change_column_null(:course_offerings, :lms_instance_id, false, 1 )
  end
end
