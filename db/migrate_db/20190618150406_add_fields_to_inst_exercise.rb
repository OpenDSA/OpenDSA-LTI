class AddFieldsToInstExercise < ActiveRecord::Migration[5.1]
  def change

    add_column :inst_exercises, :av_address, :string, limit: 512
    add_column :inst_exercises, :width, :integer
    add_column :inst_exercises, :height, :integer
    add_column :inst_exercises, :links, :text
    add_column :inst_exercises, :scripts, :text

  end
end
