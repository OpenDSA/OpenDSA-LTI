class InstModule < ActiveRecord::Base
  #~ Relationships ............................................................
  has_many :inst_chapter_modules
  has_many :inst_sections
  has_many :odsa_module_progresses

  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  def self.save_data_from_json(book, chapter, module_name, module_obj, module_position)
    mod = InstModule.find_by name: module_name
    if !mod
      mod = InstModule.new
      mod.name = module_name
      mod.save
    end

    ch_mod = InstChapterModule.new
    ch_mod.inst_chapter_id = chapter.id
    ch_mod.inst_module_id = mod.id
    ch_mod.module_position = module_position
    ch_mod.save

    sections = module_obj['sections']

    sec_position = 0
    sections.each do |k, v|
      inst_sec = InstSection.save_data_from_json(book, mod, ch_mod, k, v, sec_position)
      sec_position += 1
    end
  end
  #~ Instance methods .........................................................
  #~ Private instance methods .................................................
end
