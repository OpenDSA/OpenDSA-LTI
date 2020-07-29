class CreateOdsaExerciseAttempts < ActiveRecord::Migration[5.1]
  def change
    create_table :odsa_exercise_attempts do |t|
      t.integer  "user_id", null: false
      t.integer  "inst_book_id", null: false
      t.integer  "inst_section_id", null: false
      t.integer  "inst_book_section_exercise_id", null: false
      t.boolean  "correct", null: false
      t.datetime "time_done", null: false
      t.integer  "time_taken", null: false
      t.integer  "count_hints", null: false
      t.boolean  "hint_used", null: false
      t.decimal  "points_earned", precision: 5, scale: 2, null: false
      t.boolean  "earned_proficiency", null: false
      t.integer  "count_attempts", limit: 8, null: false
      t.string   "ip_address", limit: 20, null: false
      t.string   "question_name", limit: 50, null: false
      t.string   "request_type", limit: 50

      t.timestamps
    end
  end
end
