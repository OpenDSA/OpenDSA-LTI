class AddDescToInstBooks < ActiveRecord::Migration
  def change
    add_column :inst_books, :desc, :string
  end
end
