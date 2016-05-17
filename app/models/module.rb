
  class Module < OldDbBase
    self.table_name = 'modules'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :name, :short_display_name, :position, :created_at, :updated_at
    end

  end
