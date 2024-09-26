class AddOpenAndCloseDatesToinstChapterModules < ActiveRecord::Migration[6.0]
  def change
    add_column :inst_chapter_modules, :open_date, :datetime
    add_column :inst_chapter_modules, :close_date, :datetime
  end
end
