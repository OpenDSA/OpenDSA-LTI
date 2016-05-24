# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  factory :lms_instance do
    lms_type_id 1
    url "https://canvas.instructure.com"
    lti_key "test"
    lti_secret "secret"
  end

end