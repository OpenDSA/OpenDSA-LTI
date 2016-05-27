class AddLmsToolNumToCourseOfferings < ActiveRecord::Migration
  def change
    add_column :course_offerings, :lms_tool_num, :integer
  end
end
