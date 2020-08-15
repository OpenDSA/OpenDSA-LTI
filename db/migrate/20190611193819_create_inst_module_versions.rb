class CreateInstModuleVersions < ActiveRecord::Migration[5.1]
  def change
    create_table :inst_module_versions do |t|
      t.integer    :inst_module_id, null: false
      t.string     :name, null: false
      t.string     :git_hash, null: false          # the git commit hash for the version of the module RST file
      t.string     :file_path, null: false, limit: 4096 # path to the compiled module HTML file
      t.boolean    :template, default: false
      t.integer    :course_offering_id
      t.string     :resource_link_id
      t.string     :resource_link_title, limit: 512
      t.timestamps null: false
    end

    add_foreign_key :inst_module_versions, :inst_modules
    add_foreign_key :inst_module_versions, :course_offerings
    add_index :inst_module_versions, [:course_offering_id, :resource_link_id], unique: true, name: "index_inst_module_versions_on_course_resource"

    add_column :inst_modules, :current_version_id, :integer
    add_foreign_key :inst_modules, :inst_module_versions, column: :current_version_id, primary_key: :id

    add_column :odsa_user_interactions, :inst_module_version_id, :integer
    add_foreign_key :odsa_user_interactions, :inst_module_versions

    add_column :odsa_module_progresses, :inst_module_version_id, :integer
    add_foreign_key :odsa_module_progresses, :inst_module_versions
  end
end
