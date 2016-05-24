class CreateInstChapters < ActiveRecord::Migration
  def change
    create_table :inst_chapters do |t|
      t.integer  "inst_book_id",            limit: 4,   null: false
      t.string   "name",                    limit: 100, null: false
      t.string   "short_display_name",      limit: 45
      t.integer  "position",                limit: 4,   null: true
      t.integer  "lms_chapter_id",          limit: 4
      t.integer  "lms_assignment_group_id", limit: 4
      t.timestamps
    end

  end
end
