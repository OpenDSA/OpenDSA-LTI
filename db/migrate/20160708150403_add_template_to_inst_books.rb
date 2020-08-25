class AddTemplateToInstBooks < ActiveRecord::Migration[5.1]
  def change
    add_column :inst_books, :template, :boolean, :default => false
  end
end
