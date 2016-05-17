
  class Course < ActiveRecord::Base
    self.table_name = 'courses'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :organization_id, :creator_id, :name, :number, :created_at, :updated_at, :slug
    end

    belongs_to :organization, :foreign_key => 'organization_id', :class_name => 'Organization'
    has_many :course_offerings, :foreign_key => 'course_id', :class_name => 'CourseOffering'
    has_many :late_policies, :through => :course_offerings, :foreign_key => 'late_policy_id', :class_name => 'LatePolicy'
    has_many :terms, :through => :course_offerings, :foreign_key => 'term_id', :class_name => 'Term'
  end
