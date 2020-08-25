class CreateInstBookSectionExercises < ActiveRecord::Migration[5.1]
  def change
    create_table :inst_book_section_exercises do |t|
      t.integer  "inst_book_id",      null: false
      t.integer  "inst_section_id",   null: false
      t.integer  "inst_exercise_id",  null: false
      t.decimal  "points",                     precision: 5, scale: 2, null: false
      t.boolean  "required",             default: false
      t.decimal  "threshold",                     precision: 5, scale: 2, null: false
      t.timestamps
    end
  end
end

