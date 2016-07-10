class MakeLmsInstanceIdInCourseOfferingNotNull < ActiveRecord::Migration
  def change
    change_column_null(:course_offerings, :lms_instance_id, false, 1 )
  end
end
