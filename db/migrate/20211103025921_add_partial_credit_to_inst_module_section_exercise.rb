class AddPartialCreditToInstModuleSectionExercise < ActiveRecord::Migration[6.0]
  def change
    add_column :inst_module_section_exercises,
      :partial_credit, :boolean, default: false
  end
end
