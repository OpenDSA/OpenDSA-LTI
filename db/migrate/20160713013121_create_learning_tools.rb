class CreateLearningTools < ActiveRecord::Migration[5.1]
  def change
    create_table :learning_tools do |t|
      t.string :name, null: false
      t.string :key, null: false
      t.string :secret, null: false
      t.string :launch_url, null: false
      t.timestamps
    end
    add_index :learning_tools, :name, unique: true
  end

end
