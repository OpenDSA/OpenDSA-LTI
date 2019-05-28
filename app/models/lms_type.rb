class LmsType < ActiveRecord::Base

  HAS_LMS_LEVEL_CREDS = ['blackboardlearn']

  #~ Relationships ............................................................
  has_many :lms_instances, inverse_of: :lms_types

  #~ Validation ...............................................................

  validates :name, presence: true,
    uniqueness: { case_sensitive: true }

  def self.has_lms_level_creds?(lms_type_name)
    return LmsType::HAS_LMS_LEVEL_CREDS.include?(lms_type_name.downcase)
  end

  def has_lms_level_creds?()
    return LmsType::HAS_LMS_LEVEL_CREDS.include?(self.name.downcase)
  end

  #~ Private instance methods .................................................
end