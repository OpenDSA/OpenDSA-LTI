class AddModuleLmsAssignmentId < ActiveRecord::Migration[5.1]
  def change
    add_column :inst_chapter_modules, :lms_assignment_id, :integer
  end
end
