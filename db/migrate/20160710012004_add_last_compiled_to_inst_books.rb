class AddLastCompiledToInstBooks < ActiveRecord::Migration
  def change
    add_column :inst_books, :last_compiled, :datetime
  end
end
