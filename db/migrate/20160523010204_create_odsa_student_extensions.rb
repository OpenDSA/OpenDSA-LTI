class CreateOdsaStudentExtensions < ActiveRecord::Migration
  def change
    create_table :odsa_student_extensions do |t|
      t.integer  "user_id",         limit: 4
      t.integer  "inst_section_id", limit: 4, null: false
      t.datetime "soft_deadline"
      t.datetime "hard_deadline"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "time_limit",      limit: 4
      t.datetime "opening_date"

      t.timestamps
    end
  end
end
