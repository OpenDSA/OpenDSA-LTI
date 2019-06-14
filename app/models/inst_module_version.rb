# frozen_string_literal: true

class InstModuleVersion < ActiveRecord::Base
  belongs_to :inst_module
  belongs_to :course_offering
  has_many   :inst_module_sections, inverse_of: :inst_module_version, dependent: :destroy
  has_many   :inst_module_section_exercises, inverse_of: :inst_module_version
  has_many   :odsa_module_progresses, inverse_of: :inst_module_version, dependent: :destroy
  has_many   :odsa_user_interactions, inverse_of: :inst_module_version, dependent: :destroy

  def self.save_data_from_json(mod_path, json)
    version = nil
    InstModule.transaction do
      instmod = InstModule.find_by(path: mod_path)
      if instmod.blank?
        # this shouldn't be reachable, but include it just in case
        instmod = InstModule.new(
          path: mod_path,
          name: json['long_name']
        )
        instmod.save!
      elsif instmod.name != json['long_name']
        instmod.name = json['long_name']
      end
  
      version = InstModuleVersion.new(
        inst_module_id: instmod.id,
        name: json['long_name'],
        git_hash: json['git_hash'],
        file_path: json['file_path'],
        template: true
      )
      version.save!

      json['sections'].each do |name, json|
        InstModuleSection.save_data_from_json(name, json, version)
      end

      instmod.current_version_id = version.id
      instmod.save!
    end
    
    return version
  end

end
