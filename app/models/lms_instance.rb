class LmsInstance < ApplicationRecord
  #~ Relationships ............................................................
  has_many  :lms_accesses, inverse_of: :lms_instances
  has_many  :course_offerings, inverse_of: :lms_instance
  belongs_to  :lms_type, inverse_of: :lms_instances
  belongs_to :organization
  # has_many :users, :through => :lms_accesses

  #~ Validation ...............................................................

  validates_presence_of :lms_type, :url, :organization
  validates :url, uniqueness: true

  def self.get_oauth_creds(key)
    lms_instance = LmsInstance.where(consumer_key: key).first
    if lms_instance.blank? or lms_instance.consumer_key.blank? or lms_instance.consumer_secret.blank?
      return nil
    end
    consumer_key = lms_instance.consumer_key
    consumer_secret = lms_instance.consumer_secret
    {consumer_key => consumer_secret}
  end

  def has_oauth_creds?
    return not(self.consumer_key.blank? || self.consumer_secret.blank?)
  end

  def display_name
    "#{url}"
  end

  def openssl_private_key
    OpenSSL::PKey::RSA.new(private_key)
  end

  def openssl_public_key
    openssl_private_key.public_key
  end

  def to_jwk
    jwk = JWT::JWK.new(openssl_public_key).export
    jwk['alg'] = 'RS256'
    jwk['use'] = 'sig'
    jwk
  end

  #~ Private instance methods .................................................
end