class CreateStudentExtensions < ActiveRecord::Migration[6.0]
  def change
    create_table :student_extensions do |t|
      t.integer :user_id, index: true
      t.integer :inst_chapter_module_id, index: true

      t.datetime :open_date
      t.datetime :close_date
      t.datetime :due_date

      t.timestamps
    end

    add_foreign_key :student_extensions, :users, column: :user_id, primary_key: :id, name: "student_extensions_user_id_fk"
    add_foreign_key :student_extensions, :inst_chapter_modules, column: :inst_chapter_module_id, primary_key: :id, name: "student_extensions_inst_chapter_modules_id_fk"
  end
end
