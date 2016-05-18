
  class InstBookSectionExercise < ActiveRecord::Base
    self.table_name = 'inst_book_section_exercises'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :inst_book_id, :inst_section_id, :inst_exercise_id, :points, :created_at, :updated_at
    end

    belongs_to :inst_book, :foreign_key => 'inst_book_id', :class_name => 'InstBook'
    belongs_to :inst_section, :foreign_key => 'inst_section_id', :class_name => 'InstSection'
    has_many :odsa_exercise_attempts, :foreign_key => 'inst_book_section_exercise_id', :class_name => 'OdsaExerciseAttempt'
    has_many :odsa_exercise_progresses, :foreign_key => 'inst_book_section_exercise_id', :class_name => 'OdsaExerciseProgress'
    has_many :odsa_user_interactions, :foreign_key => 'inst_book_section_exercise_id', :class_name => 'OdsaUserInteraction'
    has_many :users_by_odsa_exercise_attempts, :source => :user, :through => :odsa_exercise_attempts, :foreign_key => 'user_id', :class_name => 'User'
    has_many :users_by_odsa_exercise_progress, :source => :user, :through => :odsa_exercise_progresses, :foreign_key => 'user_id', :class_name => 'User'
    has_many :inst_books, :through => :odsa_user_interactions, :foreign_key => 'inst_book_id', :class_name => 'InstBook'
    has_many :inst_sections, :through => :odsa_user_interactions, :foreign_key => 'inst_section_id', :class_name => 'InstSection'
    has_many :users_by_odsa_user_interactions, :source => :user, :through => :odsa_user_interactions, :foreign_key => 'user_id', :class_name => 'User'
  end
