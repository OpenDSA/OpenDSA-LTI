
  class LmsType < ActiveRecord::Base
    self.table_name = 'lms_types'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :name, :created_at, :updated_at
    end

    has_many :lms_instances, :foreign_key => 'lms_type_id', :class_name => 'LmsInstance'
  end
