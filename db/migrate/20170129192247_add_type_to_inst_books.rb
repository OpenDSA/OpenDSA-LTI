class AddTypeToInstBooks < ActiveRecord::Migration
  def change
    add_column :inst_books, :book_type, :integer
  end
end
