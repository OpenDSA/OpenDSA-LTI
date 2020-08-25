class AddTypeToInstBookSectionExercises < ActiveRecord::Migration[5.1]
  def change
    add_column :inst_book_section_exercises, :type, :boolean
  end
end
