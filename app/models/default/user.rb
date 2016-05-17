
  class User < ActiveRecord::Base
    self.table_name = 'users'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :email, :encrypted_password, :reset_password_token, :reset_password_sent_at, :remember_created_at, :sign_in_count, :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip, :last_sign_in_ip, :created_at, :updated_at, :name, :role, :global_role_id, :time_zone_id
    end

    belongs_to :global_role, :foreign_key => 'global_role_id', :class_name => 'GlobalRole'
    belongs_to :time_zone, :foreign_key => 'time_zone_id', :class_name => 'TimeZone'
    has_one :course_enrollment, :foreign_key => 'user_id', :class_name => 'CourseEnrollment'
    has_many :inst_book_owners, :foreign_key => 'users_id', :class_name => 'InstBookOwner'
    has_many :lms_accesses, :foreign_key => 'users_id', :class_name => 'LmsAccess'
    has_many :odsa_book_progresses, :foreign_key => 'user_id', :class_name => 'OdsaBookProgress'
    has_many :odsa_bugs, :foreign_key => 'user_id', :class_name => 'OdsaBug'
    has_many :odsa_exercise_attempts, :foreign_key => 'user_id', :class_name => 'OdsaExerciseAttempt'
    has_many :odsa_exercise_progresses, :foreign_key => 'user_id', :class_name => 'OdsaExerciseProgress'
    has_many :odsa_student_extensions, :foreign_key => 'user_id', :class_name => 'OdsaStudentExtension'
    has_many :odsa_user_interactions, :foreign_key => 'user_id', :class_name => 'OdsaUserInteraction'
    has_many :odsa_user_modules, :foreign_key => 'user_id', :class_name => 'OdsaUserModule'
    has_many :course_offerings, :through => :course_enrollments, :foreign_key => 'course_offering_id', :class_name => 'CourseOffering'
    has_many :course_roles, :through => :course_enrollments, :foreign_key => 'course_role_id', :class_name => 'CourseRole'
    has_many :lms_instances, :through => :lms_accesses, :foreign_key => 'lms_instance_id', :class_name => 'LmsInstance'
    has_many :inst_book_section_exercises_by_odsa_exercise_attempts, :source => :inst_book_section_exercise, :through => :odsa_exercise_attempts, :foreign_key => 'inst_book_section_exercise_id', :class_name => 'InstBookSectionExercise'
    has_many :inst_book_section_exercises_by_odsa_exercise_progress, :source => :inst_book_section_exercise, :through => :odsa_exercise_progresses, :foreign_key => 'inst_book_section_exercise_id', :class_name => 'InstBookSectionExercise'
    has_many :inst_sections_by_odsa_student_extensions, :source => :inst_section, :through => :odsa_student_extensions, :foreign_key => 'inst_sections_id', :class_name => 'InstSection'
    has_many :inst_book_section_exercises_by_odsa_user_interactions, :source => :inst_book_section_exercise, :through => :odsa_user_interactions, :foreign_key => 'inst_book_section_exercises_id', :class_name => 'InstBookSectionExercise'
    has_many :inst_books_by_odsa_user_interactions, :source => :inst_book, :through => :odsa_user_interactions, :foreign_key => 'inst_book_id', :class_name => 'InstBook'
    has_many :inst_sections_by_odsa_user_interactions, :source => :inst_section, :through => :odsa_user_interactions, :foreign_key => 'inst_section_id', :class_name => 'InstSection'
    has_many :inst_books_by_odsa_user_module, :source => :inst_book, :through => :odsa_user_modules, :foreign_key => 'inst_book_id', :class_name => 'InstBook'
  end
