
  class CourseRole < ActiveRecord::Base
    self.table_name = 'course_roles'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :name, :can_manage_course, :can_manage_assignments, :can_grade_submissions, :can_view_other_submissions, :builtin, :created_at, :updated_at
    end

    has_many :course_enrollments, :foreign_key => 'course_role_id', :class_name => 'CourseEnrollment'
    has_many :course_offerings, :through => :course_enrollments, :foreign_key => 'course_offering_id', :class_name => 'CourseOffering'
    has_many :users, :through => :course_enrollments, :foreign_key => 'user_id', :class_name => 'User'
  end
