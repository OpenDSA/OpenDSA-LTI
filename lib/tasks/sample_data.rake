require 'factory_bot'

namespace :db do
  desc "Reset database and then fill it with sample data"
  task populate: [:environment] do
    FactoryBot.create(:learning_tool)
    FactoryBot.create(:organization)
    FactoryBot.create(:term100)
    FactoryBot.create(:term200)
    FactoryBot.create(:term300)
    FactoryBot.create(:term400)
    FactoryBot.create(:term500)
    FactoryBot.create(:course)
    FactoryBot.create(:lms_instance)
    offerings = []
    offerings[0] = FactoryBot.create(:course_offering_term_1_tr)
    offerings[1] = FactoryBot.create(:course_offering_term_1_mwf)
    offerings[2] = FactoryBot.create(:course_offering_term_2_tr)
    offerings[3] = FactoryBot.create(:course_offering_term_2_mwf)
    offerings[4] = FactoryBot.create(:course_offering_term_3_tr)
    offerings[5] = FactoryBot.create(:course_offering_term_3_mwf)

    admin = FactoryBot.create(:admin)
    teacher = FactoryBot.create(:instructor_user,
          first_name: 'Ima',
          last_name:  'Teacher',
          email:      "example-1@railstutorial.org")


    students = []
    50.times do |n|
        students[n] = FactoryBot.create(:confirmed_user,
          first_name: Faker::Name.first_name,
          last_name:  Faker::Name.last_name,
          email:      "example-#{n+2}@railstutorial.org")
    end

    offerings.each do |c|
      FactoryBot.create(:course_enrollment,
        user: admin,
        course_offering: c,
        course_role: CourseRole.instructor)

      FactoryBot.create(:course_enrollment,
        user: teacher,
        course_offering: c,
        course_role: CourseRole.instructor)

      50.times do |n|
        FactoryBot.create(:course_enrollment,
          user: students[n],
          course_offering: c)
      end
    end
  end

  desc "Reset database and then fill it with Summer I 2015 data"
  task populate_su15: [:environment] do
    FactoryBot.create(:organization)
    FactoryBot.create(:term,
       season: 200,
       starts_on: "2015-05-25",
       ends_on: "2015-07-07",
       year: 2015)
    FactoryBot.create(:course)
    c = FactoryBot.create(:course_offering,
      self_enrollment_allowed: true,
      url: 'http://moodle.cs.vt.edu/course/view.php?id=282',
      label: '60396'
      )
    FactoryBot.create(:course_enrollment,
      user: FactoryBot.create(:admin),
      course_offering: c,
      course_role: CourseRole.instructor)
  end

  desc "Drop, create, and migrate"
  task :reset_all => [:drop, :create, :migrate, :seed]

  desc "Rest_all and populate"
  task :reset_populate => [:reset_all, :populate]


end
