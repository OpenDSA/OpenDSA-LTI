class AddLtiKeyAndSecretToLmsInstance < ActiveRecord::Migration
  def change
    add_column :lms_instances, :lti_key, :string
    add_column :lms_instances, :lti_secret, :string
  end
end