class InstModuleSection < ActiveRecord::Base
  belongs_to :inst_module_version
  has_many :inst_module_section_exercises, dependent: :destroy
end
