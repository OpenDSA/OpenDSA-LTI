class AddIndexOnInstChapterModuleToUserInteractions < ActiveRecord::Migration
  def change
    add_index :odsa_user_interactions, :inst_chapter_module_id, unique: false, name: "index_odsa_user_interactions_on_inst_chapter_module"
  end
end
