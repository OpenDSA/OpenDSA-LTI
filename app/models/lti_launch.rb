# app/models/lti_launch.rb
class LtiLaunch < ApplicationRecord
    belongs_to :lms_instance
    belongs_to :user
  
    validates :id_token, presence: true, uniqueness: true
    validates :expires_at, presence: true
  end
  