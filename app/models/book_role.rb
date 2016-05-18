
  class BookRole < ActiveRecord::Base
    self.table_name = 'book_roles'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :name, :can_modify, :can_compile, :created_at, :updated_at
    end

    has_many :inst_book_owners, :foreign_key => 'book_role_id', :class_name => 'InstBookOwner'
    has_many :users, :through => :inst_book_owners, :foreign_key => 'user_id', :class_name => 'User'
  end
