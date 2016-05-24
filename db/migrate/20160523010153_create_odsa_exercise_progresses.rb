class CreateOdsaExerciseProgresses < ActiveRecord::Migration
  def change
    create_table :odsa_exercise_progresses do |t|
      t.integer  "user_id",                       limit: 4,                         null: false
      t.integer  "inst_book_section_exercise_id", limit: 4,                         null: false
      t.integer  "streak",                        limit: 4,                         null: false
      t.integer  "longest_streak",                limit: 4,                         null: false
      t.datetime "first_done",                                                      null: false
      t.datetime "last_done",                                                       null: false
      t.integer  "total_done",                    limit: 4,                         null: false
      t.integer  "total_correct",                 limit: 4,                         null: false
      t.datetime "proficient_date",                                                 null: false
      t.decimal  "progress",                                precision: 5, scale: 2, null: false

      t.timestamps
    end
  end
end
