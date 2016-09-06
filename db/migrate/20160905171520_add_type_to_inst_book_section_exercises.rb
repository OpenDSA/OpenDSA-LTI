class AddTypeToInstBookSectionExercises < ActiveRecord::Migration
  def change
    add_column :inst_book_section_exercises, :type, :boolean
  end
end
