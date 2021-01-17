class CreateStudentExerciseProgresses < ActiveRecord::Migration[6.0]
    def change
      create_table :student_exercise_progresses do |t|
        t.integer :user_id, null: false
        t.integer :exercise_id, null: false
        t.text :progress
        t.decimal :grade, precision: 5, scale: 2, null: false
  
        t.timestamps
      end
    end
  end