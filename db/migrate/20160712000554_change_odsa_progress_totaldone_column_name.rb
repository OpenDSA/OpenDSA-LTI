class ChangeOdsaProgressTotaldoneColumnName < ActiveRecord::Migration[5.1]
  def change
    rename_column :odsa_exercise_progresses, :total_done, :total_correct

  end
end
