class AddInstChapterModuleIdToOdsaUserInteractions < ActiveRecord::Migration
  def change
    add_column :odsa_user_interactions, :inst_chapter_module_id, :integer
  end
end
