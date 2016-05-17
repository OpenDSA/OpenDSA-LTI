
  class OdsaBug < OldDbBase
    self.table_name = 'odsa_bugs'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :user_id, :os_family, :browser_family, :title, :description, :screenshot, :created_at, :updated_at
    end

    belongs_to :user, :foreign_key => 'user_id', :class_name => 'User'
  end
