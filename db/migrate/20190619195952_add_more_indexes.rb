class AddMoreIndexes < ActiveRecord::Migration[5.1]
  def change
    add_index :odsa_module_progresses, [:user_id, :inst_module_version_id], unique: true, name: "index_odsa_mod_prog_on_user_mod_version"
    add_index :odsa_exercise_progresses, [:user_id, :inst_module_section_exercise_id], unique: true, name: "index_odsa_ex_prog_on_user_module_sec_ex"
  end
end
