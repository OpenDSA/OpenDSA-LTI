class CreateLearningTools < ActiveRecord::Migration
  def change
    create_table :learning_tools do |t|
      t.string :name, null: false
      t.string :key, null: false
      t.string :secret, null: false
      t.string :launch_rul, null: false
    end
    add_index :learning_tools, :name, unique: true
  end

end