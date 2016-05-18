class Organization < ActiveRecord::Base
  extend FriendlyId
  friendly_id :abbreviation, use: :history


  self.table_name = 'organizations'
  self.inheritance_column = 'ruby_type'
  self.primary_key = 'id'

  if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
    attr_accessible :name, :created_at, :updated_at, :abbreviation, :slug
  end

  has_many :courses, :foreign_key => 'organization_id', :class_name => 'Course'

  #~ Private instance methods .................................................
  private

    # -------------------------------------------------------------
    # Converts a string into a book-like title, without capitalizing
    # articles or prepositions.  Note: this is different than the rails
    # titleize method in that it does not capitalize some words.  It is
    # also different than "correct" book titleizing, since it does not
    # capitalize the first word if it is an article (because we wouldn't
    # want to include it in an abbreviation), or ensure that the word "I"
    # is capitalized (because we don't expect that to appear in an org
    # name).
    def titleize(text)
      stop_words = %w(and or but in on to from with the a an)
      text.downcase.split.map{ |w|
        stop_words.include?(w) ? w : w.capitalize }.join(' ')
    end


    # -------------------------------------------------------------
    # Convert a properly capitalized name into an acronym (i.e.,
    # "Virginia Tech" => "VT") by pulling out only the capital letters.
    def acronym(text)
      titleize(text).scan(/[[:upper:]]/).join
    end


    # -------------------------------------------------------------
    def set_abbreviation_if_necessary
      if abbreviation.blank?
        self.abbreviation = acronym(name)
      end
    end


    # -------------------------------------------------------------
    def should_generate_new_friendly_id?
      set_abbreviation_if_necessary
      slug.blank? || abbreviation_changed?
    end
end
