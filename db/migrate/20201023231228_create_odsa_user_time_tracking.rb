class CreateOdsaUserTimeTracking < ActiveRecord::Migration[6.0]
  def change
    create_table :odsa_user_time_trackings do |t|
      t.integer    "user_id", null: false
      t.integer    "inst_book_id"
      t.integer    "inst_section_id"
      t.integer    "inst_book_section_exercise_id"
      t.integer    "inst_course_offering_exercise_id"
      t.integer    "inst_module_id"
      t.integer    "inst_chapter_id"
      t.integer    "inst_module_version_id"
      t.integer    "inst_module_section_exercise_id"
      t.string    "uuid", limit: 50, null: false
      t.string    "session_date", limit: 50, null: false
      t.decimal   "total_time", precision: 10, scale: 2, null: false
      t.text      "sections_time", null: false
      t.datetime  "created_at"
      t.datetime  "updated_at"
    end

    add_foreign_key :odsa_user_time_trackings, :users, name: "odsa_user_time_tracking_user_id_fk"
    add_foreign_key :odsa_user_time_trackings, :inst_books, name: "odsa_user_time_tracking_inst_book_id_fk"
    add_foreign_key :odsa_user_time_trackings, :inst_sections, name: "odsa_user_time_tracking_inst_section_id_fk"
    add_foreign_key :odsa_user_time_trackings, :inst_book_section_exercises, name: "odsa_user_time_tracking_inst_book_section_exercise_id_fk"
    add_foreign_key :odsa_user_time_trackings, :inst_modules, name: "odsa_user_time_tracking_inst_module_id_fk"
    add_foreign_key :odsa_user_time_trackings, :inst_chapters, name: "odsa_user_time_tracking_inst_chapter_id_fk"
    add_foreign_key :odsa_user_time_trackings, :inst_course_offering_exercises, name: "odsa_user_time_tracking_inst_course_offering_exercise_id_fk"
    add_foreign_key :odsa_user_time_trackings, :inst_module_versions, name: "odsa_user_time_tracking_inst_module_version_id_fk"
    add_foreign_key :odsa_user_time_trackings, :inst_module_section_exercises, name: "odsa_user_time_tracking_inst_module_section_exercise_id_fk"

    add_index :odsa_user_time_trackings, [:user_id, :uuid], unique: true, name: 'index_odsa_user_time_trackings_on_user_id_uuid'
    add_index :odsa_user_time_trackings, [:inst_book_id, :session_date], name: 'index_odsa_user_time_trackings_on_inst_book_id_session_date'
  end
end
