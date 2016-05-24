class CreateInstBookSectionExercises < ActiveRecord::Migration
  def change
    create_table :inst_book_section_exercises do |t|
      t.integer  "inst_book_id",     limit: 4,                         null: false
      t.integer  "inst_section_id",  limit: 4,                         null: false
      t.integer  "inst_exercise_id", limit: 4,                         null: false
      t.decimal  "points",                     precision: 5, scale: 2, null: false
      t.timestamps
    end
  end
end
