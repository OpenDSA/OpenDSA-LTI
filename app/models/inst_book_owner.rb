
  class InstBookOwner < ActiveRecord::Base
    self.table_name = 'inst_book_owners'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :user_id, :book_role_id, :created_at, :updated_at
    end

    belongs_to :book_role, :foreign_key => 'book_role_id', :class_name => 'BookRole'
    belongs_to :user, :foreign_key => 'user_id', :class_name => 'User'
    has_many :inst_books, :foreign_key => 'inst_book_owner_id', :class_name => 'InstBook'
    has_many :course_offerings, :through => :inst_books, :foreign_key => 'course_offering_id', :class_name => 'CourseOffering'
  end
