class ChangeOdsaProgressTotalCorrectColumnName < ActiveRecord::Migration[5.1]
  def change
    rename_column :odsa_exercise_progresses, :total_correct, :total_worth_credit
  end
end
