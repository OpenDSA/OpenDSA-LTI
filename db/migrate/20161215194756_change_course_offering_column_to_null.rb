class ChangeCourseOfferingColumnToNull < ActiveRecord::Migration
  def change
    change_column :course_offerings, :lms_course_code, :string, :null => true
  end
end
