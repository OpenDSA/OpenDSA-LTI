class InstExercise < ActiveRecord::Base
  #~ Relationships ............................................................
  has_many :inst_book_section_exercises

  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  def self.save_data_from_json(book, inst_section, exercise_name, exercise_obj, update_mode=false)
    require 'json'
    ex = InstExercise.find_by short_name: exercise_name
    if !ex and !exercise_obj['learning_tool'] and exercise_obj.is_a?(Hash)
      ex = InstExercise.new
      ex.short_name = exercise_name
      ex.name = exercise_obj['long_name']
      ex.save
    end

    if !exercise_obj.is_a?(Hash)
      ex = InstExercise.new
      ex.short_name = exercise_name
      ex.name = exercise_name
      ex.save
    end

    if exercise_obj.is_a?(Hash) and exercise_obj['learning_tool']
      book_sec_ex = InstBookSectionExercise.where("inst_book_id = ? AND inst_section_id = ?", book.id, inst_section.id).first
    else
      book_sec_ex = InstBookSectionExercise.where("inst_book_id = ? AND inst_section_id = ? AND inst_exercise_id = ?", book.id, inst_section.id, ex.id).first
    end


    if !update_mode or (update_mode and !book_sec_ex)
      book_sec_ex = InstBookSectionExercise.new
      book_sec_ex.inst_book_id = book.id
      book_sec_ex.inst_section_id = inst_section.id
    end

    if exercise_obj.is_a?(Hash) and exercise_obj['learning_tool']
      book_sec_ex.points = exercise_obj['points'] || 0
    else # OpenDSA exercise
      book_sec_ex.inst_exercise_id = ex.id
      book_sec_ex.points = exercise_obj['points'] || 0
      book_sec_ex.required = exercise_obj['required'] || false
      book_sec_ex.threshold = exercise_obj['threshold'] || 5
      book_sec_ex.options = exercise_obj['exer_options'].to_json
      if !exercise_obj.is_a?(Hash)
        book_sec_ex.type = 'dgm'
      end
    end

    book_sec_ex.save

  end
  #~ Instance methods .........................................................
  #~ Private instance methods .................................................
end