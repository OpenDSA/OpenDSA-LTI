class AddOptionsColumnToInstBookSectionExercises < ActiveRecord::Migration[5.1]
  def change
    add_column :inst_book_section_exercises, :options, :string
  end
end
