class ChangeOptionsToText < ActiveRecord::Migration[5.1]
  def self.up
    change_column :inst_book_section_exercises, :options, :text, limit: 2147483647
    change_column :inst_books, :options, :text, limit: 2147483647
  end

  def self.down
    change_column :inst_book_section_exercises, :options, :string
    change_column :inst_books, :options, :string
  end
end
