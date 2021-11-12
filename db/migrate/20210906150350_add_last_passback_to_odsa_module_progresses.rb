class AddLastPassbackToOdsaModuleProgresses < ActiveRecord::Migration[6.0]
  def change
    add_column :odsa_module_progresses, :last_passback,
      :datetime, null: false
  end
end
