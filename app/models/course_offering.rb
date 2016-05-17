
  class CourseOffering < ActiveRecord::Base
    self.table_name = 'course_offerings'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :course_id, :term_id, :label, :url, :self_enrollment_allowed, :created_at, :updated_at, :cutoff_date, :lms_course_code, :lms_course_id, :late_policy_id
    end

    belongs_to :course, :foreign_key => 'course_id', :class_name => 'Course'
    belongs_to :late_policy, :foreign_key => 'late_policy_id', :class_name => 'LatePolicy'
    belongs_to :term, :foreign_key => 'term_id', :class_name => 'Term'
    has_many :course_enrollments, :foreign_key => 'course_offering_id', :class_name => 'CourseEnrollment'
    has_many :inst_books, :foreign_key => 'course_offering_id', :class_name => 'InstBook'
    has_many :course_roles, :through => :course_enrollments, :foreign_key => 'course_role_id', :class_name => 'CourseRole'
    has_many :users, :through => :course_enrollments, :foreign_key => 'user_id', :class_name => 'User'
  end
