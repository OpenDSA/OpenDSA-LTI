# == Schema Information
#
# Table name: course_offerings
#
#  id                      :bigint           not null, primary key
#  course_id               :bigint           not null
#  term_id                 :bigint           not null
#  label                   :string(255)      not null
#  url                     :string(255)
#  self_enrollment_allowed :boolean          default(TRUE)
#  created_at              :datetime
#  updated_at              :datetime
#  cutoff_date             :date
#  late_policy_id          :bigint
#  lms_instance_id         :bigint           not null
#  lms_course_code         :string(255)
#  lms_course_num          :string(255)      not null
#  archived                :boolean          default(FALSE)
#
# Indexes
#
#  course_offerings_late_policy_id_fk                            (late_policy_id)
#  index_course_offerings_on_course_id                           (course_id)
#  index_course_offerings_on_lms_instance_id_and_lms_course_num  (lms_instance_id,lms_course_num)
#  index_course_offerings_on_term_id                             (term_id)
#

require 'spec_helper'

describe CourseOffering do
  pending "add some examples to (or delete) #{__FILE__}"
end
