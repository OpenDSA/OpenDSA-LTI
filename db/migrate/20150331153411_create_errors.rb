class CreateErrors < ActiveRecord::Migration
  def change
    create_table "errors" do |t|
      t.string   "usable_type", limit: 255
      t.integer  "usable_id",   limit: 4
      t.string   "class_name",  limit: 255
      t.text     "message",     limit: 65535
      t.text     "trace",       limit: 65535
      t.text     "target_url",  limit: 65535
      t.text     "referer_url", limit: 65535
      t.text     "params",      limit: 65535
      t.text     "user_agent",  limit: 65535
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index :errors, :class_name
    add_index :errors, :created_at
  end
end

