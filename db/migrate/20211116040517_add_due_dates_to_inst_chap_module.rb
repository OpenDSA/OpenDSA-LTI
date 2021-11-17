class AddDueDatesToInstChapModule < ActiveRecord::Migration[6.0]
  def change
    add_column :inst_chapter_modules, :due_dates, :datetime
  end
end
