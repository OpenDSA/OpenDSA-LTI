class ChangeAccessTokenColumnToNull < ActiveRecord::Migration[5.1]
  def change
    change_column :lms_accesses, :access_token, :string, :null => true
  end
end
