class AddTemplateToInstBooks < ActiveRecord::Migration
  def change
    add_column :inst_books, :template, :boolean, :default => false
  end
end
