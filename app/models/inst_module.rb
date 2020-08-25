# frozen_string_literal: true

class InstModule < ApplicationRecord
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

  def self.get_current_versions_dict()
    return Rails.cache.fetch("odsa_current_module_versions_dict", expires_in: 1.years) do
      InstModule.build_current_versions_dict()
    end
  end

  def self.get_embeddable_dict()
    return Rails.cache.fetch("odsa_embeddable_dict", expires_in: 1.years) do
      InstModule.build_embeddable_dict()
    end
  end

  # build a dictionary containing the latest module versions and their settings
  def self.build_current_versions_dict()
    versions = InstModuleVersion.includes(:inst_module, inst_module_sections: [{inst_module_section_exercises: [:inst_exercise]}])
                                .joins("INNER JOIN inst_modules ON inst_modules.current_version_id = inst_module_versions.id")
    
    dict = {}
    OpenDSA::STANDALONE_DIRECTORIES.each do |folder_name, display_name|
      dict[folder_name] = {
        'long_name' => display_name,
        'modules' => {},
      }
    end

    versions.each do |version|
      json = version.as_json(include: {
        inst_module: {}, 
        inst_module_sections: {
          include: {
            inst_module_section_exercises: {
              include: {
                inst_exercise: {}
              }
            }
          }
        }
      })
      
      path_parts = version.inst_module.path.split('/')
      if path_parts.size > 1
        json['folder_name'] = path_parts[0]
        json['mod_name'] = path_parts[1]
      else
        json['folder_name'] = 'root'
        json['mod_name'] = path_parts[0]
      end

      if dict.include?(json['folder_name'])
        dict[json['folder_name']]['modules'][json['mod_name']] = json
      end
    end
    return dict
  end

  # build a dictionary containing only modules with exercises that can be embedded
  def self.build_embeddable_dict()
    versions = InstModuleVersion.includes(:inst_module, inst_module_sections: [{inst_module_section_exercises: [:inst_exercise]}])
                                .joins("INNER JOIN inst_modules ON inst_modules.current_version_id = inst_module_versions.id")
    
    dict = {}
    OpenDSA::STANDALONE_DIRECTORIES.each do |folder_name, display_name|
      dict[folder_name] = {
        'long_name' => display_name,
        'modules' => {},
      }
    end

    versions.each do |version|
      # exclude modules with no exercises we can embed
      exclude_types = ['dgm', 'extr']
      exercises = version.inst_module_section_exercises.select{ |ex| !exclude_types.include?(ex.inst_exercise.ex_type)}
      if exercises.size == 0
        next
      end
      
      json = version.as_json(include: {
        inst_module: {}, 
        inst_module_sections: {
          include: {
            inst_module_section_exercises: {
              include: {
                inst_exercise: {}
              }
            }
          }
        }
      })
      
      path_parts = version.inst_module.path.split('/')
      if path_parts.size > 1
        json['folder_name'] = path_parts[0]
        json['mod_name'] = path_parts[1]
      else
        json['folder_name'] = 'root'
        json['mod_name'] = path_parts[0]
      end
      dict[json['folder_name']]['modules'][json['mod_name']] = json
    end
    
    dict = dict.select{ |folder_name, folder_obj| folder_obj['modules'].size > 0}

    return dict
  end

  # ~ Instance methods .........................................................
  # ~ Private instance methods .................................................
end
