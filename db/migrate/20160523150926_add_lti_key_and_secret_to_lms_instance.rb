class AddLtiKeyAndSecretToLmsInstance < ActiveRecord::Migration[5.1]
  def change
    add_column :lms_instances, :consumer_key, :string
    add_column :lms_instances, :consumer_secret, :string
  end
end
