class CreateInstModules < ActiveRecord::Migration
  def change
    create_table :inst_modules do |t|
      t.string :name, null: false
      t.string :short_display_name, limit: 50
      t.timestamps
    end

    add_index :inst_modules, :name, unique: true
  end
end
