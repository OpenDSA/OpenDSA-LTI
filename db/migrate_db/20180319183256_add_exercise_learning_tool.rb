class AddExerciseLearningTool < ActiveRecord::Migration[5.1]
  def change
    add_column :inst_exercises, :learning_tool, :string
  end
end
