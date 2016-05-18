
  class LmsInstance < ActiveRecord::Base
    self.table_name = 'lms_instance'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :lms_type_id, :url, :created_at, :updated_at
    end

    belongs_to :lms_type, :foreign_key => 'lms_type_id', :class_name => 'LmsType'
    has_many :lms_accesses, :foreign_key => 'lms_instance_id', :class_name => 'LmsAccess'
    has_many :users, :through => :lms_accesses, :foreign_key => 'user_id', :class_name => 'User'
  end
