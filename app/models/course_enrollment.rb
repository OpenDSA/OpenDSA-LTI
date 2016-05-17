
  class CourseEnrollment < ActiveRecord::Base
    self.table_name = 'course_enrollments'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :user_id, :course_offering_id, :course_role_id, :created_at, :updated_at
    end

    belongs_to :course_offering, :foreign_key => 'course_offering_id', :class_name => 'CourseOffering'
    belongs_to :course_role, :foreign_key => 'course_role_id', :class_name => 'CourseRole'
    belongs_to :user, :foreign_key => 'user_id', :class_name => 'User'
  end
