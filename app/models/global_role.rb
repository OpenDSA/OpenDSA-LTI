
  class GlobalRole < OldDbBase
    self.table_name = 'global_roles'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :name, :can_manage_all_courses, :can_edit_system_configuration, :builtin, :created_at, :updated_at
    end

    has_many :users, :foreign_key => 'global_role_id', :class_name => 'User'
    has_many :time_zones, :through => :users, :foreign_key => 'time_zone_id', :class_name => 'TimeZone'
  end
