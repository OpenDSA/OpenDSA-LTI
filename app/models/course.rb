class Course < ActiveRecord::Base
  extend FriendlyId
  friendly_id :number_without_spaces, use: [:history, :scoped],
    scope: :organization


  self.table_name = 'courses'
  self.inheritance_column = 'ruby_type'
  self.primary_key = 'id'

  if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
    attr_accessible :organization_id, :creator_id, :name, :number, :created_at, :updated_at, :slug
  end

  belongs_to :organization, :foreign_key => 'organization_id', :class_name => 'Organization'
  has_many :course_offerings, :foreign_key => 'course_id', :class_name => 'CourseOffering'
  has_many :late_policies, :through => :course_offerings, :foreign_key => 'late_policy_id', :class_name => 'LatePolicy'
  has_many :terms, :through => :course_offerings, :foreign_key => 'term_id', :class_name => 'Term'

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
