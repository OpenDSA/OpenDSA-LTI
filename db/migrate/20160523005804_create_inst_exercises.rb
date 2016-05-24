class CreateInstExercises < ActiveRecord::Migration
  def change
    create_table :inst_exercises do |t|
      t.string   "name",               limit: 50,         null: false
      t.string   "short_display_name", limit: 45
      t.string   "ex_type",            limit: 50
      t.string   "description"
      t.timestamps
    end

    add_index :inst_exercises, :name, unique: true
  end
end
