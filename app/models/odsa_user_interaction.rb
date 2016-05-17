
  class OdsaUserInteraction < OldDbBase
    self.table_name = 'odsa_user_interactions'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :inst_book_id, :user_id, :inst_section_id, :inst_book_section_exercise_id, :name, :description, :action_time, :uiid, :browser_family, :browser_version, :os_family, :os_version, :device, :ip_address, :created_at, :updated_at
    end

    belongs_to :inst_book_section_exercise, :foreign_key => 'inst_book_section_exercise_id', :class_name => 'InstBookSectionExercise'
    belongs_to :inst_book, :foreign_key => 'inst_book_id', :class_name => 'InstBook'
    belongs_to :inst_section, :foreign_key => 'inst_section_id', :class_name => 'InstSection'
    belongs_to :user, :foreign_key => 'user_id', :class_name => 'User'
  end
