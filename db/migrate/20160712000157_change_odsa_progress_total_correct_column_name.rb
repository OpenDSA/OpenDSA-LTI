class ChangeOdsaProgressTotalCorrectColumnName < ActiveRecord::Migration
  def change
    rename_column :odsa_exercise_progresses, :total_correct, :total_worth_credit
  end
end
