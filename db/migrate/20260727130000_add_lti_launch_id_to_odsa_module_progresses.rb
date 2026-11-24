class AddLtiLaunchIdToOdsaModuleProgresses < ActiveRecord::Migration[6.0]
  def change
    add_column :odsa_module_progresses, :lti_launch_id, :bigint
    add_foreign_key :odsa_module_progresses, :lti_launches
    add_index :odsa_module_progresses, :lti_launch_id, name: "index_odsa_module_progresses_on_lti_launch_id"
  end
end
