class LmsInstance < ActiveRecord::Base
  #~ Relationships ............................................................
  has_many  :lms_accesses, inverse_of: :lms_instances
  belongs_to  :lms_type, inverse_of: :lms_instances
  has_many :users, :through => :lms_accesses

  #~ Validation ...............................................................

  validates_presence_of :url


  def display_name
    "#{url}"
  end

  #~ Private instance methods .................................................
end