class CreateInstSections < ActiveRecord::Migration[5.1]
  def change
    create_table :inst_sections do |t|
      t.integer  "inst_module_id",                                   null: false
      t.integer  "inst_chapter_module_id",                           null: false
      t.string   "short_display_name",     limit: 50
      t.string     "name",                 null: false
      t.integer  "position",               limit: 4
      t.boolean  "gradable",                                  default: false
      t.datetime "soft_deadline"
      t.datetime "hard_deadline"
      t.integer  "time_limit",             limit: 4
      t.boolean "show", default: true
      t.integer  "lms_item_id"
      t.integer  "lms_assignment_id"
      t.timestamps
    end
  end
end
