# Stores the latest SPLICE state object reported by an embedded exercise
# (passed through by odsaMOD) so it can be returned for SPLICE.getState.
class AddStateToOdsaExerciseProgresses < ActiveRecord::Migration[6.0]
  def change
    # MEDIUMTEXT (16 MB): TEXT's 64 KB is too small for some exercise states
    add_column :odsa_exercise_progresses, :state, :text, size: :medium
  end
end
