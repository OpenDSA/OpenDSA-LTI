class AddPlatformColumnsToLmsInstance < ActiveRecord::Migration[6.0]
  def change
    add_column :lms_instances, :client_id, :string
    add_column :lms_instances, :private_key, :text
    add_column :lms_instances, :public_key, :text
    add_column :lms_instances, :keyset_url, :string
    add_column :lms_instances, :oauth2_url, :string
    add_column :lms_instances, :platform_oidc_auth_url, :string
  end
end