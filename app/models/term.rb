
  class Term < ActiveRecord::Base
    self.table_name = 'terms'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :season, :starts_on, :ends_on, :year, :created_at, :updated_at, :slug
    end

    has_many :course_offerings, :foreign_key => 'term_id', :class_name => 'CourseOffering'
    has_many :courses, :through => :course_offerings, :foreign_key => 'course_id', :class_name => 'Course'
    has_many :late_policies, :through => :course_offerings, :foreign_key => 'late_policy_id', :class_name => 'LatePolicy'
  end
