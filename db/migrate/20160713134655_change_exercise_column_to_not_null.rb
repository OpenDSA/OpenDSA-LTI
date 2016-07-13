class ChangeExerciseColumnToNotNull < ActiveRecord::Migration
  def change
    change_column :inst_book_section_exercises, :inst_exercise_id, :integer, :null => true
  end
end