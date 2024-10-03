# == Schema Information
#
# Table name: inst_modules
#
#  id                 :integer          not null, primary key
#  path               :string(255)      not null
#  name               :string(255)      not null
#  created_at         :datetime
#  updated_at         :datetime
#  current_version_id :integer
#
# Indexes
#
#  fk_rails_73d3622e40         (current_version_id)
#  index_inst_modules_on_path  (path) UNIQUE
#
require 'rails_helper'

RSpec.describe InstModule, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
