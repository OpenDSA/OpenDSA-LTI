class AddOptionColumnToInstBooks < ActiveRecord::Migration[5.1]
  def change
    add_column :inst_books, :options, :string
  end
end
