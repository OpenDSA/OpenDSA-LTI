
  class InstChapterModule < ActiveRecord::Base
    self.table_name = 'inst_chapter_modules'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :cnf_chapter_id, :cnf_module_id, :module_position, :created_at, :updated_at, :inst_chapters_id, :inst_modules_id
    end

    belongs_to :inst_chapter, :foreign_key => 'inst_chapters_id', :class_name => 'InstChapter'
  end
