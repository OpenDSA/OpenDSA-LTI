class InstChapter < ActiveRecord::Base
  #~ Relationships ............................................................
  belongs_to :inst_book
  has_many :inst_chapter_modules

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

    mod_position = 0
    chapter_obj.each do |k, v|
      inst_module = InstModule.save_data_from_json(book, ch, k, v, mod_position)
      mod_position += 1
    end
  end
  #~ Instance methods .........................................................
  #~ Private instance methods .................................................
end
