class CreateOdsaBookProgresses < ActiveRecord::Migration
  def change
    create_table :odsa_book_progresses do |t|
      t.integer  "user_id",                  limit: 4,          null: false
      t.integer  "inst_book_id",                  limit: 4,          null: false
      t.text     "started_exercises",        limit: 4294967295, null: false
      t.text     "all_proficient_exercises", limit: 4294967295, null: false

      t.timestamps
    end
  end
end
