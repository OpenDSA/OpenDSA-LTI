# == Schema Information
#
# Table name: late_policies
#
#  id           :integer          not null, primary key
#  name         :string(255)      not null
#  late_days    :integer          not null
#  late_percent :integer          not null
#  created_at   :datetime
#  updated_at   :datetime
#
# Indexes
#
#  index_late_policies_on_name  (name) UNIQUE
#
require 'rails_helper'

RSpec.describe LatePolicy, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
