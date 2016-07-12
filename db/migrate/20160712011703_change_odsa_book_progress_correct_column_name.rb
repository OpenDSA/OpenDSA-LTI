class ChangeOdsaBookProgressCorrectColumnName < ActiveRecord::Migration
  def change
    rename_column :odsa_book_progresses, :all_proficient_exercises, :proficient_exercises
  end
end
