class CreateOdsaUserInteractions < ActiveRecord::Migration
  def change
    create_table :odsa_user_interactions do |t|
      t.integer  "inst_book_id",                  limit: 4,          null: false
      t.integer  "user_id",                       limit: 4,          null: false
      t.integer  "inst_section_id",               limit: 4,          null: false
      t.integer  "inst_book_section_exercise_id", limit: 4,          null: false
      t.string   "name",                          limit: 50,         null: false
      t.text     "description",                   limit: 4294967295, null: false
      t.datetime "action_time",                                      null: false
      t.integer  "uiid",                          limit: 8,          null: false
      t.string   "browser_family",                limit: 20,         null: false
      t.string   "browser_version",               limit: 20,         null: false
      t.string   "os_family",                     limit: 50,         null: false
      t.string   "os_version",                    limit: 20,         null: false
      t.string   "device",                        limit: 50,         null: false
      t.string   "ip_address",                    limit: 20,         null: false

      t.timestamps
    end
  end
end
