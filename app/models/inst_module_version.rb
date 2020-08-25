# frozen_string_literal: true

# a stand-alone module (i.e. not contained in a book) that is tied directly to a course offering
class InstModuleVersion < ApplicationRecord
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

  def clone(course_offering, resource_link_id, resource_link_title)
    imv = nil
    
    InstModuleVersion.transaction do 
      imv = InstModuleVersion.new(
        inst_module_id: self.inst_module_id,
        name: self.name,
        git_hash: self.git_hash,
        file_path: self.file_path,
        template: false,
        course_offering: course_offering,
        resource_link_id: resource_link_id,
        resource_link_title: resource_link_title,
      )
      imv.save!
      
      inst_module_sections.each do |ims|
        inst_mod_sect = ims.clone(imv)
      end
    end

    return imv
  end

end
