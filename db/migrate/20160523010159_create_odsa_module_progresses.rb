class CreateOdsaModuleProgresses < ActiveRecord::Migration[5.1]
  def change
    create_table :odsa_module_progresses do |t|
      t.integer  "user_id",          null: false
      t.integer  "inst_book_id",     null: false
      t.integer  "inst_module_id",   null: false
      t.datetime "first_done",                null: false
      t.datetime "last_done",                 null: false
      t.datetime "proficient_date",           null: false

      t.timestamps
    end
  end
end
