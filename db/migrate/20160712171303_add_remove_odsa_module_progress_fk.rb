class AddRemoveOdsaModuleProgressFk < ActiveRecord::Migration[5.1]
  def change
    # remove_foreign_key :odsa_module_progresses, name: "odsa_module_progresses_inst_module_id_fk"
    # remove_column :odsa_module_progresses, :inst_module_id
    add_column :odsa_module_progresses, :inst_chapter_module_id, :integer
    add_foreign_key :odsa_module_progresses, :inst_chapter_modules
  end
end
