class CreateInstModuleSectionExercises < ActiveRecord::Migration[5.1]
  def change
    create_table :inst_module_section_exercises do |t|
      t.integer :inst_module_version_id, null: false
      t.integer :inst_module_section_id, null: false
      t.integer :inst_exercise_id, null: false
      t.decimal :points, precision: 5, scale: 2, null: false
      t.boolean :required, default: false
      t.decimal :threshold, precision: 5, scale: 2, null: false
      t.text    :options
      t.timestamps null: false
    end

    add_foreign_key :inst_module_section_exercises, :inst_module_versions
    add_foreign_key :inst_module_section_exercises, :inst_module_sections
    add_foreign_key :inst_module_section_exercises, :inst_exercises

    add_column :odsa_user_interactions, :inst_module_section_exercise_id, :integer
    add_foreign_key :odsa_user_interactions, :inst_module_section_exercises

    add_column :odsa_exercise_progresses, :inst_module_section_exercise_id, :integer
    add_foreign_key :odsa_exercise_progresses, :inst_module_section_exercises

    add_column :odsa_exercise_attempts, :inst_module_section_exercise_id, :integer
    add_foreign_key :odsa_exercise_attempts, :inst_module_section_exercises
  end
end
