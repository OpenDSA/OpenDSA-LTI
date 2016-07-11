class InstChapterModule < ActiveRecord::Base
  #~ Relationships ............................................................
  belongs_to :inst_chapter
  belongs_to :inst_module
  has_many :inst_sections, dependent: :destroy

  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  #~ Instance methods .........................................................
  # --------------------------------------------------------------------------
  # clone inst_chapter_module
  def clone(book, chapter)
    ch_mod = InstChapterModule.new
    ch_mod.inst_chapter_id = chapter.id
    ch_mod.inst_module_id = self.inst_module_id
    ch_mod.module_position = self.module_position
    ch_mod.save

    inst_sections.each do |section|
      inst_section = section.clone(book, ch_mod)
    end
  end

  #~ Private instance methods .................................................
end
