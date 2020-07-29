class AddDescToInstBooks < ActiveRecord::Migration[5.1]
  def change
    add_column :inst_books, :desc, :string
  end
end
