class LearningTool < ApplicationRecord

  #~ Relationships ............................................................
  #~ Validation ...............................................................

  validates_presence_of :name, :key, :secret, :launch_url

  #
  #~ Private instance methods .................................................
end