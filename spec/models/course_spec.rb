# == Schema Information
#
# Table name: courses
#
#  id              :bigint           not null, primary key
#  name            :string(255)      not null
#  number          :string(255)      not null
#  organization_id :bigint           not null
#  user_id         :bigint           not null
#  created_at      :datetime
#  updated_at      :datetime
#  slug            :string(255)      not null
#
# Indexes
#
#  index_courses_on_organization_id  (organization_id)
#  index_courses_on_slug             (slug)
#  index_courses_on_user_id          (user_id)
#

require 'spec_helper'

describe Course do
  pending "add some examples to (or delete) #{__FILE__}"
end
