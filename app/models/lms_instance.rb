# == Schema Information
#
# Table name: lms_instances
#
#  id                     :integer          not null, primary key
#  url                    :string(255)      not null
#  created_at             :datetime
#  updated_at             :datetime
#  lms_type_id            :integer
#  consumer_key           :string(255)
#  consumer_secret        :string(255)
#  organization_id        :integer
#  client_id              :string(255)
#  private_key            :text(65535)
#  public_key             :text(65535)
#  keyset_url             :string(255)
#  oauth2_url             :string(255)
#  platform_oidc_auth_url :string(255)
#  issuer                 :string(255)
#
# Indexes
#
#  index_lms_instances_on_url        (url) UNIQUE
#  lms_instances_lms_type_id_fk      (lms_type_id)
#  lms_instances_organization_id_fk  (organization_id)
#
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
  validates :client_id, :issuer, :keyset_url, :platform_oidc_auth_url, :oauth2_url, presence: true, if: -> { lms_type&.name == "LTI 1.3" }

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

    # Determine LTI version
  def lti_version
    if client_id.present? && oauth2_url.present?
      'LTI-1p3'
    else
      'LTI-1p0'
    end
  end

  #~ Private instance methods .................................................
end
