class CreateOdsaBugs < ActiveRecord::Migration
  def change
    create_table :odsa_bugs do |t|
      t.integer  "user_id",        limit: 4,          null: false
      t.string   "os_family",      limit: 50,         null: false
      t.string   "browser_family", limit: 20,         null: false
      t.string   "title",          limit: 50,         null: false
      t.text     "description",    limit: 4294967295, null: false
      t.string   "screenshot",     limit: 100

      t.timestamps
    end
  end
end
