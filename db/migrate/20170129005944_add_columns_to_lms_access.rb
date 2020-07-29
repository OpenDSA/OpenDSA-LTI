class AddColumnsToLmsAccess < ActiveRecord::Migration[5.1]
  def change
    add_column :lms_accesses, :consumer_key, :string
    add_column :lms_accesses, :consumer_secret, :string
  end
end
