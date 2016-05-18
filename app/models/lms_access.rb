
  class LmsAccess < ActiveRecord::Base
    self.table_name = 'lms_access'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :user_id, :lms_instance_id, :access_token, :created_at, :updated_at
    end

    belongs_to :lms_instance, :foreign_key => 'lms_instance_id', :class_name => 'LmsInstance'
    belongs_to :user, :foreign_key => 'user_id', :class_name => 'User'
  end
