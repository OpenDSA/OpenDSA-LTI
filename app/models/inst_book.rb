  #~ Relationships ............................................................
  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  #~ Instance methods .........................................................
  #~ Private instance methods .................................................
class InstBook < ActiveRecord::Base

  #~ Relationships ............................................................
  belongs_to :course_offering
  # has_many    :inst_book_owners, inverse_of: :inst_book
  has_many    :inst_book_owners, inverse_of: :inst_book
  has_many :inst_book_section_exercises
  has_many :inst_chapters
  has_many :odsa_module_progresses
  has_many :odsa_user_interactions
  has_many :inst_sections_by_inst_book_section_exercises, :source => :inst_section, :through => :inst_book_section_exercises
  has_many :users_by_odsa_module_progress, :source => :user, :through => :odsa_module_progresses
  has_many :inst_book_section_exercises_by_odsa_user_interactions, :source => :inst_book_section_exercise, :through => :odsa_user_interactions
  has_many :inst_sections_by_odsa_user_interactions, :source => :inst_section, :through => :odsa_user_interactions
  has_many :users_by_odsa_user_interactions, :source => :user, :through => :odsa_user_interactions

  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  def self.save_data_from_json(json)
    book_data = json
    b = InstBook.new
    b.title = book_data['title']
    b.book_url = book_data['book_url']
    b.book_code = book_data['book_code']
    b.save

    chapters = book_data['chapters']

    ch_position = 0
    chapters.each do |k,v|
      inst_chapter = InstChapter.save_data_from_json(b, k, v, ch_position)
      ch_position += 1
    end
  end

  #~ Instance methods .........................................................
  #~ Private instance methods .................................................
end
