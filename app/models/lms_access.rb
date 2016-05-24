class LmsAccess < ActiveRecord::Base
  #~ Relationships ............................................................

  belongs_to :lms_instance, inverse_of: :lms_accesses
  belongs_to :user, inverse_of: :lms_accesses

  #~ Validation ...............................................................

  validates :access_token, presence: true

end