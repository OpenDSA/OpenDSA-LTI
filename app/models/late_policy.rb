
  class LatePolicy < ActiveRecord::Base
    self.table_name = 'late_policies'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :name, :late_days, :late_percent, :created_at, :updated_at
    end

    has_many :course_offerings, :foreign_key => 'late_policy_id', :class_name => 'CourseOffering'
    has_many :courses, :through => :course_offerings, :foreign_key => 'course_id', :class_name => 'Course'
    has_many :terms, :through => :course_offerings, :foreign_key => 'term_id', :class_name => 'Term'
  end
