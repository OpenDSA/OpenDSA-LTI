class AddOptionsColumnToInstBookSectionExercises < ActiveRecord::Migration
  def change
    add_column :inst_book_section_exercises, :options, :string
  end
end
