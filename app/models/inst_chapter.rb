class InstChapter < ActiveRecord::Base
  #~ Relationships ............................................................
  belongs_to :inst_book
  has_many :inst_chapter_modules, dependent: :destroy

  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  def self.save_data_from_json(book, chapter_name, chapter_obj, chapter_position)
    ch = InstChapter.new
    ch.inst_book_id = book.id
    ch.name = chapter_name
    ch.position = chapter_position
    ch.save

    mod_position = 1
    chapter_obj.each do |k, v|
      inst_module = InstModule.save_data_from_json(book, ch, k, v, mod_position)
      mod_position += 1
    end
  end
  #~ Instance methods .........................................................
  # --------------------------------------------------------------------------
  # clone chapter
  def clone(inst_book)
    ch = InstChapter.new
    ch.inst_book_id = inst_book.id
    ch.name = self.name
    ch.short_display_name = self.short_display_name
    ch.position = self.position
    ch.save

    inst_chapter_modules.each do |chapter_module|
      inst_chapter_module = chapter_module.clone(inst_book, ch)
    end
  end

  #~ Private instance methods .................................................
end
