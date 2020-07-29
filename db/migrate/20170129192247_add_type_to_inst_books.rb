class AddTypeToInstBooks < ActiveRecord::Migration[5.1]
  def change
    add_column :inst_books, :book_type, :integer
  end
end
