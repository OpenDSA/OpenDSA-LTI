class CreateInstChapterModules < ActiveRecord::Migration[5.1]
  def change
    create_table :inst_chapter_modules do |t|
      t.integer  "inst_chapter_id", limit: 4, null: false
      t.integer  "inst_module_id",  limit: 4, null: false
      t.integer  "module_position", limit: 4
      t.integer  "lms_module_item_id"
      t.integer  "lms_section_item_id"

      t.timestamps
    end
  end
end
