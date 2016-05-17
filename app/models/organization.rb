
  class Organization < ActiveRecord::Base
    self.table_name = 'organizations'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :name, :created_at, :updated_at, :abbreviation, :slug
    end

    has_many :courses, :foreign_key => 'organization_id', :class_name => 'Course'
  end
