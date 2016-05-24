class CreateInstSections < ActiveRecord::Migration
  def change
    create_table :inst_sections do |t|
      t.integer  "inst_module_id",         limit: 4,                          null: false
      t.integer  "inst_chapter_module_id", limit: 4,                          null: false
      t.string   "short_display_name",     limit: 50
      t.string     "name",                 null: false
      t.integer  "position",               limit: 4
      t.boolean  "gradable",                                  default: false
      t.datetime "soft_deadline"
      t.datetime "hard_deadline"
      t.integer  "time_limit",             limit: 4
      t.timestamps
    end
  end
end
