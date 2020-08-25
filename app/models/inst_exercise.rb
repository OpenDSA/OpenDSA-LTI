class InstExercise < ApplicationRecord
  #~ Relationships ............................................................
  has_many :inst_book_section_exercises
  has_many :inst_course_offering_exercises

  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................
  def self.save_data_from_json(book, inst_section, exercise_name, exercise_obj, update_mode = false)
    # puts "inst_exercises"
    require 'json'
    ex = InstExercise.find_by short_name: exercise_name
    if !ex and exercise_obj.is_a?(Hash)
      if exercise_obj['learning_tool']
        ex = InstExercise.new
        ex.short_name = exercise_obj['resource_name']
        ex.name = exercise_obj['resource_name']
        ex.learning_tool = exercise_obj['learning_tool']
        ex.save
      else
        ex = InstExercise.new
        ex.short_name = exercise_name
        ex.name = exercise_obj['long_name']
        ex.save
      end
    end

    if !exercise_obj.is_a?(Hash)
      ex = InstExercise.new
      ex.short_name = exercise_name
      ex.name = exercise_name
      ex.save
    end

    if exercise_obj.is_a?(Hash) and exercise_obj['learning_tool']
      book_sec_ex = InstBookSectionExercise.find_by(inst_book_id: book.id,
                                                    inst_section_id: inst_section.id)
    else
      book_sec_ex = InstBookSectionExercise.find_by(inst_book_id: book.id,
                                                    inst_section_id: inst_section.id,
                                                    inst_exercise_id: ex.id)
    end

    if !update_mode or (update_mode and !book_sec_ex)
      book_sec_ex = InstBookSectionExercise.new
      book_sec_ex.inst_book_id = book.id
      book_sec_ex.inst_section_id = inst_section.id
    end

    if exercise_obj.is_a?(Hash) and exercise_obj['learning_tool']
      book_sec_ex.inst_exercise_id = ex.id
      book_sec_ex.points = exercise_obj['points'] || 0
      book_sec_ex.required = exercise_obj['required'] || false
      book_sec_ex.threshold = 100
    else # OpenDSA exercise
      book_sec_ex.inst_exercise_id = ex.id
      # puts exercise_obj['points']
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

  def self.get_av_dimensions(av_path)
    path = File.join(OpenDSA::OPENDSA_DIRECTORY, av_path)
    doc = File.open(path) do |f|
      Nokogiri::HTML(f)
    end
    attrib = doc.at('body').attributes
    if attrib.has_key?('data-width') and attrib.has_key?('data-height')
      return {
               'width': attrib['data-width'].value.to_i,
               'height': attrib['data-height'].value.to_i,
             }
    end
    return nil
  end
  
  def self.embed_url(host, short_name)
    return "#{host}/embed/#{short_name}"
  end

  def self.embed_code(host, short_name, av_address=nil, height=nil)
    url = InstExercise.embed_url(host, short_name)
    if !av_address.blank?
      return "<iframe src=\"#{url}\" height=\"#{height || 950}\" width=\"100%\" scrolling=\"no\"></iframe>"
    end
    return "<iframe src=\"#{url}\" height=\"600\" width=\"100%\"></iframe>"    
  end

  #~ Instance methods .........................................................

  def embed_url(host)
    return InstExercise.embed_url(host, self.short_name)
  end

  def embed_code(host)
    return InstExercise.embed_code(host, self.av_address, self.height)
  end
  
  #~ Private instance methods .................................................
end
