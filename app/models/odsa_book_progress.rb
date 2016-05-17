
  class OdsaBookProgress < ActiveRecord::Base
    self.table_name = 'odsa_book_progress'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :user_id, :book_id, :started_exercises, :all_proficient_exercises, :users_id, :created_at, :updated_at
    end

    belongs_to :user, :foreign_key => 'user_id', :class_name => 'User'
  end
