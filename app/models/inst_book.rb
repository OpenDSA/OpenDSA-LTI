
  class InstBook < ActiveRecord::Base
    self.table_name = 'inst_books'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :title, :book_url, :course_offering_id, :cnf_book_id, :created_at, :updated_at, :cnf_book_users_id
    end

    belongs_to :course_offering, :foreign_key => 'course_offering_id', :class_name => 'CourseOffering'
    has_one :inst_book_section_exercise, :foreign_key => 'inst_book_id', :class_name => 'InstBookSectionExercise'
    has_many :odsa_user_interactions, :foreign_key => 'inst_book_id', :class_name => 'OdsaUserInteraction'
    has_many :odsa_user_modules, :foreign_key => 'inst_book_id', :class_name => 'OdsaUserModule'
    has_many :inst_sections_by_inst_book_section_exercises, :source => :inst_section, :through => :inst_book_section_exercises, :foreign_key => 'inst_section_id', :class_name => 'InstSection'
    has_many :inst_book_section_exercises, :through => :odsa_user_interactions, :foreign_key => 'inst_book_section_exercises_id', :class_name => 'InstBookSectionExercise'
    has_many :inst_sections_by_odsa_user_interactions, :source => :inst_section, :through => :odsa_user_interactions, :foreign_key => 'inst_section_id', :class_name => 'InstSection'
    has_many :users_by_odsa_user_interactions, :source => :user, :through => :odsa_user_interactions, :foreign_key => 'user_id', :class_name => 'User'
    has_many :users_by_odsa_user_module, :source => :user, :through => :odsa_user_modules, :foreign_key => 'user_id', :class_name => 'User'
  end
