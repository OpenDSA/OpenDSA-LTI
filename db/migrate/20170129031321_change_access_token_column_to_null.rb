class ChangeAccessTokenColumnToNull < ActiveRecord::Migration
  def change
    change_column :lms_accesses, :access_token, :string, :null => true
  end
end
