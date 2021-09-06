# == Schema Information
#
# Table name: lms_accesses
#
#  id              :bigint           not null, primary key
#  access_token    :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  lms_instance_id :bigint           not null
#  user_id         :bigint           not null
#  consumer_key    :string(255)
#  consumer_secret :string(255)
#
# Indexes
#
#  index_lms_accesses_on_lms_instance_id_and_user_id  (lms_instance_id,user_id) UNIQUE
#  lms_accesses_user_id_fk                            (user_id)
#
require 'rails_helper'

RSpec.describe LmsAccess, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
