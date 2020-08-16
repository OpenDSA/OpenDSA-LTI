class AddLastCompiledToInstBooks < ActiveRecord::Migration[5.1]
  def change
    add_column :inst_books, :last_compiled, :datetime
  end
end
