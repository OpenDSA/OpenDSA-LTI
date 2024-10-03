# == Schema Information
#
# Table name: lti_launches
#
#  id                 :bigint           not null, primary key
#  lms_instance_id    :integer          not null
#  user_id            :integer          not null
#  course_offering_id :integer          not null
#  id_token           :text(65535)
#  decoded_jwt        :text(4294967295)
#  kid                :string(255)
#  expires_at         :datetime         not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  fk_rails_73ea582aae                       (lms_instance_id)
#  fk_rails_bb7142408e                       (user_id)
#  index_lti_launches_on_course_offering_id  (course_offering_id)
#  index_lti_launches_on_expires_at          (expires_at)
#

# =============================================================================
# Represents a single launch event for LTI 1.3
# Each launch is associated with an LMS instance, 
# a user, and a specific course offering.
#
class LtiLaunch < ApplicationRecord

  #~ Relationships ............................................................

  belongs_to :lms_instance, inverse_of: :lti_launches
  belongs_to :user, inverse_of: :lti_launches
  belongs_to :course_offering, inverse_of: :lti_launches

  #~ Validations ..............................................................

  validates :id_token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  #~ Private instance methods .................................................

end
