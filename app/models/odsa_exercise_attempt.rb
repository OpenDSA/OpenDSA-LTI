
  class OdsaExerciseAttempt < OldDbBase
    self.table_name = 'odsa_exercise_attempts'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :user_id, :inst_book_section_exercise_id, :correct, :time_done, :time_taken, :count_hints, :hint_used, :points_earned, :earned_proficiency, :count_attempts, :ip_address, :ex_question, :created_at, :updated_at
    end

    belongs_to :inst_book_section_exercise, :foreign_key => 'inst_book_section_exercise_id', :class_name => 'InstBookSectionExercise'
    belongs_to :user, :foreign_key => 'user_id', :class_name => 'User'
  end
