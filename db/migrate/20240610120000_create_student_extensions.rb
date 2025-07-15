class CreateStudentExtensions < ActiveRecord::Migration[6.0]
  def change
    create_table :student_extensions do |t|
      t.integer :user_id, null: false
      t.integer :inst_chapter_module_id, null: false

      # Deadline fields
      t.datetime :open_deadline
      t.datetime :due_deadline
      t.datetime :close_deadline

      t.integer :time_limit
      t.timestamps
    end
    add_index :student_extensions, [:user_id, :inst_chapter_module_id], unique: true
    add_foreign_key :student_extensions, :users
    add_foreign_key :student_extensions, :inst_chapter_modules
  end
end 