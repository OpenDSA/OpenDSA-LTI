
  class InstBookRole < ActiveRecord::Base
    self.table_name = 'inst_book_roles'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :name, :can_modify, :can_compile, :created_at, :updated_at
    end

  end
