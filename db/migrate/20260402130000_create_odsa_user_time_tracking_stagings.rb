class CreateOdsaUserTimeTrackingStagings < ActiveRecord::Migration[6.0]
  def change
    create_table :odsa_user_time_tracking_stagings do |t|
      t.integer :user_id, null: false
      t.integer :inst_book_id
      t.integer :inst_module_id
      t.integer :inst_chapter_id
      t.string :uuid, limit: 50, null: false
      t.string :session_date, limit: 50, null: false
      t.decimal :total_time, precision: 10, scale: 2, null: false
      t.text :sections_time, null: false
      t.datetime :created_at
      t.datetime :updated_at
    end

    add_foreign_key :odsa_user_time_tracking_stagings, :users, name: "odsa_user_time_tracking_staging_user_id_fk"
    add_foreign_key :odsa_user_time_tracking_stagings, :inst_books, name: "odsa_user_time_tracking_staging_inst_book_id_fk"
    add_foreign_key :odsa_user_time_tracking_stagings, :inst_modules, name: "odsa_user_time_tracking_staging_inst_module_id_fk"
    add_foreign_key :odsa_user_time_tracking_stagings, :inst_chapters, name: "odsa_user_time_tracking_staging_inst_chapter_id_fk"

    add_index :odsa_user_time_tracking_stagings, [:user_id, :uuid], unique: true, name: "index_odsa_user_time_tracking_stagings_on_user_id_uuid"
    add_index :odsa_user_time_tracking_stagings, [:inst_book_id, :session_date], name: "idx_oustt_on_book_and_date"
    add_index :odsa_user_time_tracking_stagings,
              [:user_id, :inst_book_id, :inst_module_id, :inst_chapter_id, :session_date],
              name: "idx_oustt_on_daily_merge_key"
  end
end
