# == Schema Information
#
# Table name: inst_module_sections
#
#  id                     :bigint           not null, primary key
#  inst_module_version_id :bigint           not null
#  name                   :string(255)      not null
#  show                   :boolean          default(TRUE)
#  learning_tool          :string(255)
#  resource_type          :string(255)
#  resource_name          :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  fk_rails_ff11275e48  (inst_module_version_id)
#
# a section in a stand-alone module
class InstModuleSection < ApplicationRecord
  belongs_to :inst_module_version
  has_many :inst_module_section_exercises, dependent: :destroy

  def self.save_data_from_json(section_name, json, inst_module_version)
    sec = InstModuleSection.new(
      inst_module_version: inst_module_version,
      name: section_name
    )
    sec.show = json.key?('showsection') ? json['showsection'] : true
    sec.learning_tool = json['learning_tool']
    sec.resource_type = json['resource_type']
    sec.resource_name = json['resource_name']
    sec.save!

    if json['learning_tool'] and json['resource_type'] == 'external_assignment'
      InstModuleSectionExercise.save_data_from_json(inst_module_version, sec, json['resource_name'], json)
    else # OpenDSA section
      json.each do |k, v|
        InstModuleSectionExercise.save_data_from_json(inst_module_version, sec, k, v) if v.is_a?(Hash)
      end
    end
  end

  def clone(inst_module_version)
    ims = InstModuleSection.new(
      inst_module_version: inst_module_version,
      name: self.name,
      show: self.show,
      learning_tool: self.learning_tool,
      resource_type: self.resource_type,
      resource_name: self.resource_name
    )
    ims.save!

    self.inst_module_section_exercises.each do |imse|
      imse.clone(inst_module_version, ims)
    end
    
    return ims
  end

end
