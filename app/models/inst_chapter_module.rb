
  class InstChapterModule < OldDbBase
    self.table_name = 'inst_chapter_modules'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :inst_chapter_id, :inst_module_id, :module_position, :created_at, :updated_at
    end

    belongs_to :inst_chapter, :foreign_key => 'inst_chapter_id', :class_name => 'InstChapter'
    has_many :inst_sections, :foreign_key => 'inst_chapter_module_id', :class_name => 'InstSection'
  end
