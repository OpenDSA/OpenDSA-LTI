class InstModuleVersion < ActiveRecord::Base
    belongs_to :inst_module
    belongs_to :course_offering
    has_many   :inst_module_sections, inverse_of: :inst_module_version, dependent: :destroy
    has_many   :odsa_module_progresses, inverse_of: :inst_module_version, dependent: :destroy
    has_many   :odsa_user_interactions, inverse_of: :inst_module_version, dependent: :destroy
end
