# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do

  factory :lms_instance do
    lms_type_id 1
    url "https://canvas.instructure.com"
    consumer_key "test"
    consumer_secret "secret"
  end

end