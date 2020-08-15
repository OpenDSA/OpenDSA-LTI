class ChangeLmsCourseNumToString < ActiveRecord::Migration[5.1]
  def change
    change_column :course_offerings, :lms_course_num, :string

    add_index :course_offerings, [:lms_instance_id, :lms_course_num]
  end
end
