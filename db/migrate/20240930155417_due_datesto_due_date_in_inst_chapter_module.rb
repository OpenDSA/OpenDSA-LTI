class DueDatestoDueDateInInstChapterModule < ActiveRecord::Migration[6.0]
  def change
    rename_column :inst_chapter_modules, :due_dates, :due_date
  end
end
