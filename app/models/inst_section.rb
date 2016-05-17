
  class InstSection < OldDbBase
    self.table_name = 'inst_sections'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :inst_module_id, :inst_chapter_module_id, :short_display_name, :name, :position, :gradable, :soft_deadline, :hard_deadline, :time_limit, :created_at, :updated_at
    end

    belongs_to :inst_chapter_module, :foreign_key => 'inst_chapter_module_id', :class_name => 'InstChapterModule'
    has_many :inst_book_section_exercises, :foreign_key => 'inst_section_id', :class_name => 'InstBookSectionExercise'
    has_many :odsa_student_extensions, :foreign_key => 'inst_section_id', :class_name => 'OdsaStudentExtension'
    has_many :odsa_user_interactions, :foreign_key => 'inst_section_id', :class_name => 'OdsaUserInteraction'
    has_many :inst_books_by_inst_book_section_exercises, :source => :inst_book, :through => :inst_book_section_exercises, :foreign_key => 'inst_book_id', :class_name => 'InstBook'
    has_many :users_by_odsa_student_extensions, :source => :user, :through => :odsa_student_extensions, :foreign_key => 'user_id', :class_name => 'User'
    has_many :inst_book_section_exercises_by_odsa_user_interactions, :source => :inst_book_section_exercise, :through => :odsa_user_interactions, :foreign_key => 'inst_book_section_exercise_id', :class_name => 'InstBookSectionExercise'
    has_many :inst_books_by_odsa_user_interactions, :source => :inst_book, :through => :odsa_user_interactions, :foreign_key => 'inst_book_id', :class_name => 'InstBook'
    has_many :users_by_odsa_user_interactions, :source => :user, :through => :odsa_user_interactions, :foreign_key => 'user_id', :class_name => 'User'
  end
