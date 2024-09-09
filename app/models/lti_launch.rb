# == Schema Information
#
# Table name: lti_launches
#
#  id                :bigint           not null, primary key
#  lms_instance_id   :integer          not null
#  user_id           :integer          not null
#  course_offering_id: integer          not null
#  id_token          :text             not null
#  decoded_jwt       :json
#  kid               :string
#  expires_at        :datetime         not null
#  created_at        :datetime
#  updated_at        :datetime
#
# Indexes
#
#  index_lti_launches_on_lms_instance_id_and_user_id       (lms_instance_id, user_id)
#  index_lti_launches_on_course_offering_id                (course_offering_id)
#  index_lti_launches_on_expires_at                        (expires_at)
#
# Foreign Keys
#
#  fk_lti_launches_lms_instance_id   (lms_instance_id => lms_instances.id)
#  fk_lti_launches_user_id           (user_id => users.id)
#  fk_lti_launches_course_offering_id (course_offering_id => course_offerings.id)

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