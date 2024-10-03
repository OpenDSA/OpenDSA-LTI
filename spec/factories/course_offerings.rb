# == Schema Information
#
# Table name: course_offerings
#
#  id                      :integer          not null, primary key
#  course_id               :integer          not null
#  term_id                 :integer          not null
#  label                   :string(255)      not null
#  url                     :string(255)
#  self_enrollment_allowed :boolean          default(TRUE)
#  created_at              :datetime
#  updated_at              :datetime
#  cutoff_date             :date
#  late_policy_id          :integer
#  lms_instance_id         :integer          not null
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

FactoryBot.define do

  factory :course_offering do
    course_id { 1 }
    late_policy_id { 1 }
    url { "http://courses.cs.vt.edu/~cs2114/Fall2013" }
    self_enrollment_allowed { true }
    lms_instance_id { 1 }
    lms_course_num { 1 }

    factory :course_offering_term_1_tr do
      term_id { 1 }
      label { "TR 11:00am" }
    end

    factory :course_offering_term_1_mwf do
      term_id { 1 }
      label { "MWF 10:00am" }
    end

    factory :course_offering_term_2_tr do
      term_id { 2 }
      label { "TR 11:00am" }
    end

    factory :course_offering_term_2_mwf do
      term_id { 2 }
      label { "MWF 10:00am" }
    end

    factory :course_offering_term_3_tr do
      term_id { 3 }
      label { "TR 11:00am" }
    end

    factory :course_offering_term_3_mwf do
      term_id { 3 }
      label { "MWF 10:00am" }
    end

  end

end
