# This file should contain all the record creation needed to seed the
# database with its default values.  The data can then be loaded with
# the rake db:seed (or created alongside the db with db:setup).

# ---------------------------------------------------------------
# Create the default LMS types.
#
LmsType.delete_all

LmsType.create!(
  name:                          'Canvas')
LmsType.create!(
  name:                          'moodle')
LmsType.create!(
  name:                          'BlackboardLearn')

# ---------------------------------------------------------------
# Create the default late policies.
#
LatePolicy.delete_all

LatePolicy.create!(
  name:                          '0_days',
  late_days:                     0,
  late_percent:                 0)

LatePolicy.create!(
  name:                          '3_days',
  late_days:                     3,
  late_percent:                 50)

LatePolicy.create!(
  name:                          '5_days',
  late_days:                     5,
  late_percent:                 50)

# ---------------------------------------------------------------
# Create the default built-in roles. The order of these must match the
# order of the IDs in models/global_role.rb.
#
GlobalRole.delete_all

GlobalRole.create!(
  name:                          'Administrator',
  builtin:                       true,
  can_edit_system_configuration: true,
  can_manage_all_courses:        true)

GlobalRole.create!(name:         'Instructor',
  builtin:                       true,
  can_edit_system_configuration: false,
  can_manage_all_courses:        false)

GlobalRole.create!(name:         'Regular User',
  builtin:                       true,
  can_edit_system_configuration: false,
  can_manage_all_courses:        false)

GlobalRole.create!(name:         'Researcher',
  builtin:                       true,
  can_edit_system_configuration: false,
  can_manage_all_courses:        false)

# ---------------------------------------------------------------
# Create the default course roles. The order of these must match the
# order of the IDs in models/course_role.rb.
#
CourseRole.delete_all

CourseRole.create!(
  name:                       'Instructor',
  builtin:                    true,
  can_manage_course:          true,
  can_manage_assignments:     true,
  can_grade_submissions:      true,
  can_view_other_submissions: true)

CourseRole.create!(
  name:                       'Grader',
  builtin:                    true,
  can_manage_course:          false,
  can_manage_assignments:     false,
  can_grade_submissions:      true,
  can_view_other_submissions: true)

CourseRole.create!(
  name:                       'Student',
  builtin:                    true,
  can_manage_course:          false,
  can_manage_assignments:     false,
  can_grade_submissions:      false,
  can_view_other_submissions: false)

 # -----------------------------------------
 # Create the different timezone objects in
 # the timezones table

 TimeZone.create!(
  name: 'America/New_York',
  zone: 'UTC -05:00',
  display_as: 'UTC -05:00(New York)',
  name_formatted: 'Eastern Time (US & Canada)')
  
  TimeZone.create!(
  name: 'America/Chicago',
  zone: 'UTC -06:00',
  display_as: 'UTC -06:00(Chicago)',
  name_formatted: 'Central Time (US & Canada)')
  
  TimeZone.create!(
  name: 'America/Denver',
  zone: 'UTC -07:00',
  display_as: 'UTC -07:00(Denver)',
  name_formatted: 'Mountain Time (US & Canada)')
  
  TimeZone.create!(
  name: 'America/Los_Angeles',
  zone: 'UTC -08:00',
  display_as: 'UTC -08:00(Los Angeles)',
  name_formatted: 'Pacific Time (US & Canada)')
  
  TimeZone.create!(
  name: 'America/Anchorage',
  zone: 'UTC -09:00',
  display_as: 'UTC -09:00(Anchorage)',
  name_formatted: 'Alaska')
  
  TimeZone.create!(
  name: 'Pacific/Honolulu',
  zone: 'UTC -10:00',
  display_as: 'UTC -10:00(Honolulu)',
  name_formatted: 'Hawaii')
  
  TimeZone.create!(
  name: 'Pacific/Midway',
  zone: 'UTC -11:00',
  display_as: 'UTC -11:00(Midway)',
  name_formatted: 'Midway Island')
  
  TimeZone.create!(
  name: 'Pacific/Auckland',
  zone: 'UTC +12:00',
  display_as: 'UTC +12:00(Auckland)',
  name_formatted: 'Auckland')
  
  TimeZone.create!(
  name: 'Pacific/Guadalcanal',
  zone: 'UTC +11:00',
  display_as: 'UTC +11:00(Guadalcanal)',
  name_formatted: 'Magadan')
  
  TimeZone.create!(
  name: 'Australia/Sydney',
  zone: 'UTC +10:00',
  display_as: 'UTC +10:00(Sydney)',
  name_formatted: 'Melbourne')
  
  TimeZone.create!(
  name: 'Asia/Tokyo',
  zone: 'UTC +09:00',
  display_as: 'UTC +09:00(Tokyo)',
  name_formatted: 'Tokyo')
  
  TimeZone.create!(
  name: 'Asia/Shanghai',
  zone: 'UTC +08:00',
  display_as: 'UTC +08:00(Shanghai)',
  name_formatted: 'Beijing')
  
  TimeZone.create!(
  name: 'Asia/Bangkok',
  zone: 'UTC +07:00',
  display_as: 'UTC +07:00(Bangkok)',
  name_formatted: 'Bangkok')
  
  TimeZone.create!(
  name: 'Asia/Dhaka',
  zone: 'UTC +06:00',
  display_as: 'UTC +06:00(Dhaka)',
  name_formatted: 'Dhaka')
  
  TimeZone.create!(
  name: 'Asia/Karachi',
  zone: 'UTC +05:00',
  display_as: 'UTC +05:00(Karachi)',
  name_formatted: 'Karachi')
  
  TimeZone.create!(
  name: 'Europe/Moscow',
  zone: 'UTC +03:00',
  display_as: 'UTC +03:00(Moscow)',
  name_formatted: 'Moscow')
  
  TimeZone.create!(
  name: 'Europe/Kiev',
  zone: 'UTC +02:00',
  display_as: 'UTC +02:00(Kiev)',
  name_formatted: 'Kyiv')
  
  TimeZone.create!(
  name: 'Europe/Paris',
  zone: 'UTC +01:00',
  display_as: 'UTC +01:00(Paris)',
  name_formatted: 'Paris')
  
  TimeZone.create!(
  name: 'Europe/Samara',
  zone: 'UTC +04:00',
  display_as: 'UTC +04:00(Samara)',
  name_formatted: 'Samara')
  
  TimeZone.create!(
  name: 'Europe/London',
  zone: 'UTC',
  display_as: 'UTC(London)',
  name_formatted: 'UTC')
  
  TimeZone.create!(
  name: 'Atlantic/Azores',
  zone: 'UTC -01:00',
  display_as: 'UTC -01:00(Azores)',
  name_formatted: 'Azores')
  
  TimeZone.create!(
  name: 'Atlantic/South_Georgia',
  zone: 'UTC -02:00',
  display_as: 'UTC -02:00(South Georgia)',
  name_formatted: 'Mid-Atlantic')
  
  TimeZone.create!(
  name: 'America/Montevideo',
  zone: 'UTC -03:00',
  display_as: 'UTC -03:00(Montevideo)',
  name_formatted: 'Montevideo')
  
  TimeZone.create!(
  name: 'America/Halifax',
  zone: 'UTC -04:00',
  display_as: 'UTC  -04:00(Halifax)',
  name_formatted: 'Atlantic Time (Canada)')
  
  TimeZone.create!(
  name: 'Asia/Kolkata',
  zone: 'UTC +05:30',
  display_as: 'UTC  +05:30(Kolkata)',
  name_formatted: 'Kolkata')

