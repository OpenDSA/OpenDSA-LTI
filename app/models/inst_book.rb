
  class InstBook < OldDbBase
    self.table_name = 'inst_books'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :course_offering_id, :inst_book_owner_id, :title, :book_url, :created_at, :updated_at
    end

    belongs_to :course_offering, :foreign_key => 'course_offering_id', :class_name => 'CourseOffering'
    belongs_to :inst_book_owner, :foreign_key => 'inst_book_owner_id', :class_name => 'InstBookOwner'
    has_many :inst_book_section_exercises, :foreign_key => 'inst_book_id', :class_name => 'InstBookSectionExercise'
    has_many :inst_chapters, :foreign_key => 'inst_book_id', :class_name => 'InstChapter'
    has_many :odsa_module_progresses, :foreign_key => 'inst_book_id', :class_name => 'OdsaModuleProgress'
    has_many :odsa_user_interactions, :foreign_key => 'inst_book_id', :class_name => 'OdsaUserInteraction'
    has_many :inst_sections_by_inst_book_section_exercises, :source => :inst_section, :through => :inst_book_section_exercises, :foreign_key => 'inst_section_id', :class_name => 'InstSection'
    has_many :users_by_odsa_module_progress, :source => :user, :through => :odsa_module_progresses, :foreign_key => 'user_id', :class_name => 'User'
    has_many :inst_book_section_exercises_by_odsa_user_interactions, :source => :inst_book_section_exercise, :through => :odsa_user_interactions, :foreign_key => 'inst_book_section_exercise_id', :class_name => 'InstBookSectionExercise'
    has_many :inst_sections_by_odsa_user_interactions, :source => :inst_section, :through => :odsa_user_interactions, :foreign_key => 'inst_section_id', :class_name => 'InstSection'
    has_many :users_by_odsa_user_interactions, :source => :user, :through => :odsa_user_interactions, :foreign_key => 'user_id', :class_name => 'User'
  end
