
  class OdsaStudentExtension < ActiveRecord::Base
    self.table_name = 'odsa_student_extensions'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :user_id, :inst_sections_id, :soft_deadline, :hard_deadline, :created_at, :updated_at, :time_limit, :opening_date
    end

    belongs_to :inst_section, :foreign_key => 'inst_sections_id', :class_name => 'InstSection'
    belongs_to :user, :foreign_key => 'user_id', :class_name => 'User'
  end
