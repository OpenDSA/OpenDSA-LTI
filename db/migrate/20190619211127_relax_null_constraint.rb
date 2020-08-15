class RelaxNullConstraint < ActiveRecord::Migration[5.1]
  def change
    change_column_null :odsa_module_progresses, :inst_book_id, true
    change_column_default :odsa_module_progresses, :inst_book_id, nil
  end
end
