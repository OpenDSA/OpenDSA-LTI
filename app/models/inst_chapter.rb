
  class InstChapter < ActiveRecord::Base
    self.table_name = 'inst_chapters'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :inst_book_id, :name, :short_display_name, :position, :lms_chapter_id, :lms_assignment_group_id, :created_at, :updated_at
    end

    belongs_to :inst_book, :foreign_key => 'inst_book_id', :class_name => 'InstBook'
    has_many :inst_chapter_modules, :foreign_key => 'inst_chapter_id', :class_name => 'InstChapterModule'
  end
