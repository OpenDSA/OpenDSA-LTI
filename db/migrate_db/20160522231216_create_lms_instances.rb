class CreateLmsInstances < ActiveRecord::Migration[5.1]
  def change
    create_table :lms_instances do |t|
      t.string :url, null: false

      t.timestamps
    end

    add_index :lms_instances, :url, unique: true
  end
end
