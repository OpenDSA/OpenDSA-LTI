class AddColumnsToInstSections < ActiveRecord::Migration[5.1]
  def change
    add_column :inst_sections, :learning_tool, :string
    add_column :inst_sections, :resource_type, :string
    add_column :inst_sections, :resource_name, :string
  end
end
