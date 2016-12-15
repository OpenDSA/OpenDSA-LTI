class RemoveUniqueIndexLmsAccesses < ActiveRecord::Migration
  def change
    remove_index :lms_accesses, [:lms_instance_id, :access_token]
  end
end
