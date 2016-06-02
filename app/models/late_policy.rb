class LatePolicy < ActiveRecord::Base

  #~ Relationships ............................................................
  has_many :course_offerings, inverse_of: :late_policy
  has_many :courses, :through => :course_offerings
  has_many :terms, :through => :course_offerings


  #~ Validation ...............................................................

  validates :name, presence: true, uniqueness: { case_sensitive: true }

  #~ Private instance methods .................................................
end