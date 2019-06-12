class CreateInstModuleSections < ActiveRecord::Migration
  def change
    create_table :inst_module_sections do |t|
      t.integer   :inst_module_version_id, null: false
      t.string    :name, null: false
      t.boolean   :show, default: true
      t.timestamps null: false
    end

    add_foreign_key :inst_module_sections, :inst_module_versions
  end
end
