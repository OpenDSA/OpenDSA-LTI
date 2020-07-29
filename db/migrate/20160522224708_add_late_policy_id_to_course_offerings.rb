class AddLatePolicyIdToCourseOfferings < ActiveRecord::Migration[5.1]
  def change
    add_column :course_offerings, :late_policy_id, :integer
    add_foreign_key :course_offerings, :late_policies
  end
end
