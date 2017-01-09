class AddArchivedToCourseOfferings < ActiveRecord::Migration
  def change
    add_column :course_offerings, :archived, :boolean, :default => false
  end
end
