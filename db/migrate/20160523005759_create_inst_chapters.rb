class CreateInstChapters < ActiveRecord::Migration[5.1]
  def change
    create_table :inst_chapters do |t|
      t.integer  "inst_book_id",            null: false
      t.string   "name",                    limit: 100, null: false
      t.string   "short_display_name",      limit: 45
      t.integer  "position",                 null: true
      t.integer  "lms_chapter_id"
      t.integer  "lms_assignment_group_id"
      t.timestamps
    end

  end
end
