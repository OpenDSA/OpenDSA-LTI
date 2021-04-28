class AddIssuerColumnToLmsInstance < ActiveRecord::Migration[6.0]
  def change
    add_column :lms_instances, :issuer, :string
  end
end
