# == Schema Information
#
# Table name: lms_instances
#
#  id              :bigint           not null, primary key
#  url             :string(255)      not null
#  created_at      :datetime
#  updated_at      :datetime
#  lms_type_id     :bigint
#  consumer_key    :string(255)
#  consumer_secret :string(255)
#  organization_id :bigint
#  client_id        :string
#  private_key      :text
#  public_key       :text
#  keyset_url       :string
#  oauth2_url       :string
#  platform_oidc_auth_url :string
#  issuer           :string
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
  has_many  :lti_launches, inverse_of: :lms_instance
  belongs_to  :lms_type, inverse_of: :lms_instances
  belongs_to :organization
  # has_many :users, :through => :lms_accesses

  #~ Callbacks ..............................................................
  # Auto-generate a 2048-bit RSA keypair on create for LTI 1.3 instances
  # if the admin didn't paste one in. LTI 1.1 instances use
  # consumer_key/consumer_secret instead and don't need a keypair.
  # Mirrors Lti13Service::DynamicRegistration#generate_keypair so manual
  # and dynamic registrations produce equivalent keypairs.
  before_create :generate_keypair, if: -> { private_key.blank? && lti_version == 'LTI-1p3' }

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

  # Generate a 2048-bit RSA keypair and assign both PEMs. Called from
  # the before_create callback when no private_key was provided, but
  # also usable on an existing instance to rotate keys (call save
  # afterwards).
  def generate_keypair
    rsa = OpenSSL::PKey::RSA.new(2048)
    self.private_key = rsa.to_pem
    self.public_key  = rsa.public_key.to_pem
  end

    # Determine LTI version
  def lti_version
    if client_id.present? && oauth2_url.present?
      'LTI-1p3'
    else
      'LTI-1p0'
    end
  end

  # True if this LmsInstance has the configuration needed for LTI 1.3
  # (client_id + oauth2_url; private_key is auto-generated on save).
  # LTI 1.1 is always available — its consumer_key/consumer_secret are
  # derived per-user from LmsAccess (see User#update_lms_access), not
  # stored on the LmsInstance — so there is no supports_lti_1p1?
  # counterpart.
  def supports_lti_1p3?
    client_id.present? && oauth2_url.present?
  end

  #~ Private instance methods .................................................
end
