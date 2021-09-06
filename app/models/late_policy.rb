# == Schema Information
#
# Table name: late_policies
#
#  id           :bigint           not null, primary key
#  name         :string(255)      not null
#  late_days    :bigint           not null
#  late_percent :bigint           not null
#  created_at   :datetime
#  updated_at   :datetime
#
# Indexes
#
#  index_late_policies_on_name  (name) UNIQUE
#
class LatePolicy < ApplicationRecord

  #~ Relationships ............................................................
  has_many :course_offerings, inverse_of: :late_policy
  # has_many :courses, :through => :course_offerings
  # has_many :terms, :through => :course_offerings


  #~ Validation ...............................................................

  validates :name, presence: true, uniqueness: { case_sensitive: true }

  #~ Private instance methods .................................................
end
