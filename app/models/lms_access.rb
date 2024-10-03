# == Schema Information
#
# Table name: lms_accesses
#
#  id              :integer          not null, primary key
#  access_token    :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  lms_instance_id :integer          not null
#  user_id         :integer          not null
#  consumer_key    :string(255)
#  consumer_secret :string(255)
#
# Indexes
#
#  index_lms_accesses_on_lms_instance_id_and_user_id  (lms_instance_id,user_id) UNIQUE
#  lms_accesses_user_id_fk                            (user_id)
#
class LmsAccess < ApplicationRecord
  #~ Relationships ............................................................

  belongs_to :lms_instance, inverse_of: :lms_accesses
  belongs_to :user, inverse_of: :lms_accesses

  #~ Validation ...............................................................

  validates_presence_of :lms_instance, :user
  validates :lms_instance, uniqueness: { scope: :user }

  def self.get_oauth_creds(key)
    lms_access = LmsAccess.where(consumer_key: key).first
    if lms_access.blank?
      return nil
    end
    consumer_key = lms_access.consumer_key
    consumer_secret = lms_access.consumer_secret
    {consumer_key => consumer_secret}
  end

  def self.get_consumer_secret(key)
    LmsAccess.where(consumer_key: key).pluck(:consumer_secret)
  end
end
