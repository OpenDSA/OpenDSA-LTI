class AddArchivedToCourseOfferings < ActiveRecord::Migration[5.1]
  def change
    add_column :course_offerings, :archived, :boolean, :default => false
  end
end
