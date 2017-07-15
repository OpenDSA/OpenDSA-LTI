class ChangeUserIdAndLmsInstanceIdToNotNull < ActiveRecord::Migration
  def change
    change_column_null(:lms_accesses, :lms_instance_id, false, 1 )
    change_column_null(:lms_accesses, :user_id, false )
  end
end
