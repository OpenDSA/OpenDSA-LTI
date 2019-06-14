# frozen_string_literal: true

class InstModule < ActiveRecord::Base
  # ~ Relationships ............................................................
  has_many :inst_chapter_modules
  has_many :inst_sections
  has_many :inst_module_versions, inverse_of: :inst_module
  belongs_to :current_version, class_name: 'InstModuleVersion'

  # ~ Validation ...............................................................
  # ~ Constants ................................................................
  # ~ Hooks ....................................................................
  # ~ Class methods ............................................................
  def self.save_data_from_json(book, chapter, module_path, module_obj, module_position, update_mode = false)
    # puts "inst_modules"
    mod = InstModule.find_by path: module_path
    if !mod
      mod = InstModule.new
      mod.path = module_path
      mod.name = module_obj['long_name']
      mod.save
    elsif mod.name != module_obj['long_name']
      # update module name
      mod.name = module_obj['long_name']
      mod.save
    end

    ch_mod = InstChapterModule.where('inst_chapter_id = ? AND inst_module_id = ?', chapter.id, mod.id).first

    if !update_mode || (update_mode && !ch_mod)
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

  # Given a list of module paths, returns a list of module paths for modules
  # whose current version is outdated
  def self.outdated_module_paths(module_paths, language, verbose=false)
    outdated = {}
    rst_directory = File.join(OpenDSA::RST_DIRECTORY, language)
    count = 0
    Dir.chdir(rst_directory) do
      module_paths.each do |module_path|
        if verbose
          count += 1
          printf("\rChecking module #{count} of #{module_paths.size}")
        end
        rst_path = module_path + '.rst'
        module_file_basename = module_path.split('/')[-1]
        module_obj = InstModule.find_by(path: module_path)
        if module_obj.blank?
          # the module name will be properly set later
          module_obj = InstModule.new(
            path: module_path,
            name: module_file_basename
          )
          module_obj.save
        end
        # hash of the git commit where the module's RST file was last modified
        git_hash = %x(git log -n 1 --pretty=format:%H -- #{rst_path})
        module_version = InstModuleVersion.find_by(template: true, inst_module_id: module_obj.id, git_hash: git_hash)
        if module_version.blank?
          outdated[module_path] = git_hash
        end
      end
    end
    printf("\n") if verbose
    return outdated
  end

  # ~ Instance methods .........................................................
  # ~ Private instance methods .................................................
end
