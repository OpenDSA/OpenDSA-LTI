class AddInstChapterModuleIdToOdsaUserInteractions < ActiveRecord::Migration[5.1]
  def change
    add_column :odsa_user_interactions, :inst_chapter_module_id, :integer
  end
end
