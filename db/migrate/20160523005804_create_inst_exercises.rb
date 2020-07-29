class CreateInstExercises < ActiveRecord::Migration[5.1]
  def change
    create_table :inst_exercises do |t|
      t.string   "name"
      t.string   "short_name",         null: false
      t.string   "ex_type",            limit: 50
      t.string   "description"
      t.timestamps
    end

    add_index :inst_exercises, :short_name, unique: true
  end
end
