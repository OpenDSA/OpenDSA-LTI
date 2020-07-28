# == Schema Information
#
# Table name: courses
#
#  id              :integer          not null, primary key
#  name            :string(255)      default(""), not null
#  number          :string(255)      default(""), not null
#  organization_id :integer          not null
#  created_at      :datetime
#  updated_at      :datetime
#  creator_id      :integer
#  slug            :string(255)      default(""), not null
#
# Indexes
#
#  index_courses_on_organization_id  (organization_id)
#  index_courses_on_slug             (slug)
#

# =============================================================================
# Represents a course at a university; akin to the course's catalog
# description.  A course may have one or more course offerings in any
# specific term.
#
class Course < ApplicationRecord
  extend FriendlyId
  friendly_id :number_without_spaces, use: [:history, :scoped],
    scope: :organization


  #~ Relationships ............................................................

  belongs_to  :organization, inverse_of: :courses
  belongs_to  :user, inverse_of: :courses
  has_many    :course_offerings, inverse_of: :course, dependent: :destroy
  # # Associating with exercises through course_exercises
  # has_many    :course_exercises, inverse_of: :course, dependent: :destroy
  # has_many    :exercises, through: :course_exercises

  #Kaminari for the show method
  paginates_per 100

  accepts_nested_attributes_for :course_offerings, allow_destroy: true


  #~ Validation ...............................................................

  validates_presence_of :name, :number, :organization


  #~ Class methods ............................................................

  # -------------------------------------------------------------
  def self.search(terms)
    resultant = []
    term_array = terms.split
    term_array.each do |term|
      term = "%" + term + "%"
      Course.where("name LIKE ?",term).find_each do |course|
        resultant<<course.id
      end
    end

    return resultant
  end


  # -------------------------------------------------------------

  def active_course_offerings
    course_offerings.where(archived: false)
  end

  # -------------------------------------------------------------
  def display_name
    number_and_name
  end


  # -------------------------------------------------------------
  def number_and_name
    "#{number}: #{name}"
  end


  # -------------------------------------------------------------
  def number_and_org
    "#{number} (#{organization.abbreviation})"
  end


  # -------------------------------------------------------------
  def number_and_organization
    "#{number} (#{organization.name})"
  end


  #~ Private instance methods .................................................
  private

    # -------------------------------------------------------------
    def number_without_spaces
      number.gsub(/\s/, '')
    end


    # -------------------------------------------------------------
    def should_generate_new_friendly_id?
      slug.blank? || number_changed?
    end

end
