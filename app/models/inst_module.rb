class InstModule < ActiveRecord::Base
  #~ Relationships ............................................................
  has_many :inst_chapter_modules
  has_many :inst_sections


  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  def self.save_data_from_json(book, chapter, module_path, module_obj, module_position, update_mode=false)
    # puts "inst_modules"
    mod = InstModule.find_by path: module_path
    if !mod
      mod = InstModule.new
      mod.path = module_path
      mod.name = module_obj['long_name']
      mod.save
    end

    ch_mod = InstChapterModule.where("inst_chapter_id = ? AND inst_module_id = ?", chapter.id, mod.id).first

    if !update_mode or (update_mode and !ch_mod)
      ch_mod = InstChapterModule.new
      ch_mod.inst_chapter_id = chapter.id
      ch_mod.inst_module_id = mod.id
    end
    ch_mod.module_position = module_position
    ch_mod.save

    sections = module_obj['sections'] || {}

    sec_position = 0
    sections.each do |k, v|
      if v.is_a?(Hash)
        inst_sec = InstSection.save_data_from_json(book, mod, ch_mod, k, v, sec_position, update_mode)
        sec_position += 1
      end
    end
  end
  #~ Instance methods .........................................................
  #~ Private instance methods .................................................
end
