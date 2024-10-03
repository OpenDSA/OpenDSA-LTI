# == Schema Information
#
# Table name: inst_module_sections
#
#  id                     :integer          not null, primary key
#  inst_module_version_id :integer          not null
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
require 'rails_helper'

RSpec.describe InstModuleSection, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
