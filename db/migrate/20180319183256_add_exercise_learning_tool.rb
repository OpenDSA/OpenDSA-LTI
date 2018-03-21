class AddExerciseLearningTool < ActiveRecord::Migration
  def change
    add_column :inst_exercises, :learning_tool, :string
  end
end
