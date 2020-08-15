class AddLmsInstanceIdToCourseOffering < ActiveRecord::Migration[5.1]
  def change
    add_column :course_offerings, :lms_instance_id, :integer
    add_column :course_offerings, :lms_course_code, :string
    add_column :course_offerings, :lms_course_num, :integer

    add_foreign_key :course_offerings, :lms_instances
  end
end
