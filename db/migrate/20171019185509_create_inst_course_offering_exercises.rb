class CreateInstCourseOfferingExercises < ActiveRecord::Migration[5.1]
  def change
    create_table :inst_course_offering_exercises do |t|
      t.integer :course_offering_id, null: false
      t.integer :inst_exercise_id, null: false
      t.string :resource_link_id, null: false
      t.string :resource_link_title
      t.timestamps
    end
    add_foreign_key :inst_course_offering_exercises, :inst_exercises
    add_foreign_key :inst_course_offering_exercises, :course_offerings

    change_column_null :odsa_user_interactions, :inst_book_id, true
    add_column :odsa_user_interactions, :inst_course_offering_exercise_id, :integer
    add_foreign_key :odsa_user_interactions, :inst_course_offering_exercises
    
    change_column_null :odsa_exercise_attempts, :inst_book_id, true
    change_column_null :odsa_exercise_attempts, :inst_section_id, true
    change_column_null :odsa_exercise_attempts, :inst_book_section_exercise_id, true
    add_column :odsa_exercise_attempts, :inst_course_offering_exercise_id, :integer
    add_foreign_key :odsa_exercise_attempts, :inst_course_offering_exercises

    change_column_null :odsa_exercise_progresses, :inst_book_section_exercise_id, true
    add_column :odsa_exercise_progresses, :inst_course_offering_exercise_id, :integer
    add_foreign_key :odsa_exercise_progresses, :inst_course_offering_exercises

  end
end
