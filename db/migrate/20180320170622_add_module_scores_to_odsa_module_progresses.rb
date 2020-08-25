class AddModuleScoresToOdsaModuleProgresses < ActiveRecord::Migration[5.1]
  def change
    add_column :odsa_module_progresses, :lis_outcome_service_url, :string
    add_column :odsa_module_progresses, :lis_result_sourcedid, :string
    add_column :odsa_module_progresses, :current_score, :float
    add_column :odsa_module_progresses, :highest_score, :float
    add_index :odsa_module_progresses, [:user_id, :inst_chapter_module_id], unique: true, name: "index_odsa_module_progress_on_user_and_module"
  end
end
