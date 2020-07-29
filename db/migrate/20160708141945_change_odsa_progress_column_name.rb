class ChangeOdsaProgressColumnName < ActiveRecord::Migration[5.1]
  def change
    rename_column :odsa_exercise_progresses, :streak, :current_score
    rename_column :odsa_exercise_progresses, :longest_streak, :highest_score

    add_index :odsa_exercise_progresses, [:user_id, :inst_book_section_exercise_id], :unique => true, name: 'index_odsa_ex_prog_on_user_id_and_inst_bk_sec_ex_id'

  end
end
