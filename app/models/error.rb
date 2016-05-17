
  class Error < OldDbBase
    self.table_name = 'errors'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :usable_type, :usable_id, :class_name, :message, :trace, :target_url, :referer_url, :params, :user_agent, :created_at, :updated_at
    end

  end
