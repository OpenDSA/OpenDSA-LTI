class CreateOdsaModuleProgresses < ActiveRecord::Migration
  def change
    create_table :odsa_module_progresses do |t|
      t.integer  "user_id",         limit: 4, null: false
      t.integer  "inst_book_id",    limit: 4, null: false
      t.integer  "inst_module_id",  limit: 4, null: false
      t.datetime "first_done",                null: false
      t.datetime "last_done",                 null: false
      t.datetime "proficient_date",           null: false

      t.timestamps
    end
  end
end
