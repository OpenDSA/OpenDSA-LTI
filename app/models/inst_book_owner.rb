
  class InstBookOwner < ActiveRecord::Base
    self.table_name = 'inst_book_owners'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :cnf_book_role_id, :users_id, :created_at, :updated_at
    end

    belongs_to :user, :foreign_key => 'users_id', :class_name => 'User'
  end
