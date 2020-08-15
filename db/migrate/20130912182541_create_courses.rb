class CreateCourses < ActiveRecord::Migration[5.1]
  def change
    create_table :courses do |t|
      t.string :name, null: false
      t.string :number, null: false
      t.references :organization, null: false, index: true
      t.references :user, null: false, index: true
      t.string :url_part, null: false

      t.timestamps
    end

    add_index :courses, :url_part, unique: true
  end
end
