class AddOptionColumnToInstBooks < ActiveRecord::Migration
  def change
    add_column :inst_books, :options, :string
  end
end
