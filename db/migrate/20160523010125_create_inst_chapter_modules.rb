class CreateInstChapterModules < ActiveRecord::Migration
  def change
    create_table :inst_chapter_modules do |t|
      t.integer  "inst_chapter_id", limit: 4, null: false
      t.integer  "inst_module_id",  limit: 4, null: false
      t.integer  "module_position", limit: 4

      t.timestamps
    end
  end
end
