class LmsAccess < ActiveRecord::Base
  #~ Relationships ............................................................

  belongs_to :lms_instance, inverse_of: :lms_accesses
  belongs_to :user, inverse_of: :lms_accesses

  #~ Validation ...............................................................

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
