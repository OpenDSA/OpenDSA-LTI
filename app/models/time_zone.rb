
  class TimeZone < OldDbBase
    self.table_name = 'time_zones'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :name, :zone, :display_as, :created_at, :updated_at
    end

    has_many :users, :foreign_key => 'time_zone_id', :class_name => 'User'
    has_many :global_roles, :through => :users, :foreign_key => 'global_role_id', :class_name => 'GlobalRole'
  end
