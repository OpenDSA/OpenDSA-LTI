class AddUniqueIndexOdsaBookProgress < ActiveRecord::Migration[5.1]
  def change
    add_index :odsa_book_progresses, [:user_id, :inst_book_id], unique: true
  end
end
