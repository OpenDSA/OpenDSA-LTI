class CreateOdsaStudentExtensions < ActiveRecord::Migration[5.1]
  def change
    create_table :odsa_student_extensions do |t|
      t.integer  "user_id"
      t.integer  "inst_section_id", null: false
      t.datetime "soft_deadline"
      t.datetime "hard_deadline"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "time_limit"
      t.datetime "opening_date"

      t.timestamps
    end
  end
end
