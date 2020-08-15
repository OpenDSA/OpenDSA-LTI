class AddIndexOnInstChapterModuleToUserInteractions < ActiveRecord::Migration[5.1]
  def change
    add_index :odsa_user_interactions, :inst_chapter_module_id, unique: false, name: "index_odsa_user_interactions_on_inst_chapter_module"
  end
end
