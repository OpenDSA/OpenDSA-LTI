class AddJsonToInstBookSectionExercise < ActiveRecord::Migration[6.0]
  def change
    add_column :inst_book_section_exercises,
      :json, :text, limit: 65535
  end
end
