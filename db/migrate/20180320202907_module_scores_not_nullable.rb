class ModuleScoresNotNullable < ActiveRecord::Migration[5.1]
  def change
    change_column_null(:odsa_module_progresses, :current_score, false, 0)
    change_column_null(:odsa_module_progresses, :highest_score, false, 0)
  end
end
