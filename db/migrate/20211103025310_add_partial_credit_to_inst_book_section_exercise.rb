class AddPartialCreditToInstBookSectionExercise < ActiveRecord::Migration[6.0]
  def change
    add_column :inst_book_section_exercises,
      :partial_credit, :boolean, default: false
  end
end
