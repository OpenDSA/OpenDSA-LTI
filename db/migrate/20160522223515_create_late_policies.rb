class CreateLatePolicies < ActiveRecord::Migration
  def change
    create_table :late_policies do |t|
      t.string :name, null: false
      t.integer :late_days, null: false
      t.integer :late_percent, null: false

      t.timestamps
    end
    add_index :late_policies, :name, unique: true

  end
end