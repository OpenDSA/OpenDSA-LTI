class CreateBookRoles < ActiveRecord::Migration
  def change
    create_table :book_roles do |t|
      t.string   "name",        limit: 45,                null: false
      t.boolean  "can_modify",             default: true
      t.boolean  "can_compile",            default: true
      t.timestamps
    end
    add_index :book_roles, :name, unique: true
  end
end

