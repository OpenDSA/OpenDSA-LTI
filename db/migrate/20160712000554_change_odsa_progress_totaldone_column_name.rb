class ChangeOdsaProgressTotaldoneColumnName < ActiveRecord::Migration
  def change
    rename_column :odsa_exercise_progresses, :total_done, :total_correct

  end
end
