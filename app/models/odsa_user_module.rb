
  class OdsaUserModule < ActiveRecord::Base
    self.table_name = 'odsa_user_module'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :user_id, :inst_book_id, :inst_module_id, :first_done, :last_done, :proficient_date, :created_at, :updated_at
    end

    belongs_to :inst_book, :foreign_key => 'inst_book_id', :class_name => 'InstBook'
    belongs_to :user, :foreign_key => 'user_id', :class_name => 'User'
  end
