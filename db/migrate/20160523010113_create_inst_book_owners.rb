class CreateInstBookOwners < ActiveRecord::Migration
  def change
    create_table :inst_book_owners do |t|
      t.integer  "user_id",      limit: 4, null: false
      t.integer  "inst_book_id",      limit: 4, null: false
      t.integer  "book_role_id", limit: 4, null: false

      t.timestamps
    end

    add_index :inst_book_owners, [:inst_book_id, :user_id], unique: true
  end
end
