# == Schema Information
#
# Table name: learning_tools
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  key        :string(255)      not null
#  secret     :string(255)      not null
#  launch_url :string(255)      not null
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_learning_tools_on_name  (name) UNIQUE
#
class LearningTool < ApplicationRecord

  #~ Relationships ............................................................
  #~ Validation ...............................................................

  validates_presence_of :name, :key, :secret, :launch_url

  #
  #~ Private instance methods .................................................
end
