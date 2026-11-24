class AddCompositeIndexToOdsaExerciseAttempts < ActiveRecord::Migration[6.0]
  def change
    add_index :odsa_exercise_attempts, [:user_id, :inst_book_section_exercise_id],
              name: 'idx_attempts_user_ibse'
  end
end
