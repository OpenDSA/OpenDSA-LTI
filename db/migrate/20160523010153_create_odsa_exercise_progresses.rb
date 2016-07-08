class CreateOdsaExerciseProgresses < ActiveRecord::Migration
  def change
    create_table :odsa_exercise_progresses do |t|
      t.integer  "user_id", null: false
      t.integer  "inst_book_section_exercise_id", null: false
      t.integer  "current_score", null: false
      t.integer  "highest_score", null: false
      t.datetime "first_done", null: false
      t.datetime "last_done", null: false
      t.integer  "total_done", null: false
      t.integer  "total_correct", null: false
      t.datetime "proficient_date", null: false
      t.decimal  "progress", precision: 5, scale: 2, null: false
      t.string "current_exercise"
      t.string "correct_exercises"
      t.string "hinted_exercise"
      t.timestamps
    end

    add_index :odsa_exercise_progresses, [:user_id, :inst_book_section_exercise_id], :unique => true, name: 'index_odsa_ex_prog_on_user_id_and_inst_bk_sec_ex_id'
  end
end
