  #~ Relationships ............................................................
  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  #~ Instance methods .........................................................
  #~ Private instance methods .................................................
class InstBook < ActiveRecord::Base

  #~ Relationships ............................................................
  belongs_to :course_offering, inverse_of: :inst_books
  belongs_to :user, inverse_of: :inst_books
  has_many :inst_chapters
  has_many :inst_book_section_exercises
  has_many :odsa_user_interactions
  has_many :odsa_module_progresses
  has_many :odsa_exercise_attempts

  paginates_per 100

  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  def self.save_data_from_json(json, current_user)
    book_data = json
    b = InstBook.new
    b.title = book_data['title']
    b.user_id = current_user.id
    b.save

    chapters = book_data['chapters']

    ch_position = 0
    chapters.each do |k,v|
      inst_chapter = InstChapter.save_data_from_json(b, k, v, ch_position)
      ch_position += 1
    end
  end

  #~ Instance methods .........................................................
  # --------------------------------------------------------------------------
  # return lms credintials associated with the course offering
  def lms_creds
    consumer_key = course_offering.lms_instance['consumer_key']
    consumer_secret = course_offering.lms_instance['consumer_secret']
    {consumer_key => consumer_secret}
  end
  #~ Private instance methods .................................................
end
