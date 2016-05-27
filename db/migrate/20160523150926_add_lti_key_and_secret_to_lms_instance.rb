class AddLtiKeyAndSecretToLmsInstance < ActiveRecord::Migration
  def change
    add_column :lms_instances, :consumer_key, :string
    add_column :lms_instances, :consumer_secret, :string
  end
end