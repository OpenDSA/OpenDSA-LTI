class CreateInstModules < ActiveRecord::Migration[5.1]
  def change
    create_table :inst_modules do |t|
      t.string :path, null: false
      t.string :name, null: false
      t.timestamps
    end

    add_index :inst_modules, :path, unique: true
  end
end
