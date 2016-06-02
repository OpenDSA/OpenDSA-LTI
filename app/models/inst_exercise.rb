class InstExercise < ActiveRecord::Base
  #~ Relationships ............................................................
  has_many :inst_book_section_exercises

  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  def self.save_data_from_json(book, inst_section, exercise_name, exercise_obj)
    ex = InstExercise.find_by short_name: exercise_name
    if !ex
      ex = InstExercise.new
      ex.short_name = exercise_name
      ex.name = exercise_obj['long_name']
      ex.save
    end

    book_sec_ex = InstBookSectionExercise.new
    book_sec_ex.inst_book_id = book.id
    book_sec_ex.inst_section_id = inst_section.id
    book_sec_ex.inst_exercise_id = ex.id
    book_sec_ex.points = exercise_obj['points'] || 0
    book_sec_ex.required = exercise_obj['required'] || false
    book_sec_ex.threshold = exercise_obj['threshold'] || 5
    book_sec_ex.save

  end
  #~ Instance methods .........................................................
  #~ Private instance methods .................................................
end