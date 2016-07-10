class MakeLmsCourseInCourseOfferingNotNull < ActiveRecord::Migration
  def change
    change_column_null(:course_offerings, :lms_course_code, false, 1 )
    change_column_null(:course_offerings, :lms_course_num, false, 1 )
  end
end
