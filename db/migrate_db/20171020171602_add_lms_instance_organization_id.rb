class AddLmsInstanceOrganizationId < ActiveRecord::Migration[5.1]
  def change
    add_column :lms_instances, :organization_id, :integer
    add_foreign_key :lms_instances, :organizations
  end
end
