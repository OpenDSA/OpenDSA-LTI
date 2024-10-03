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

FactoryBot.define do

  factory :lms_instance do
    lms_type_id { 1 }
    organization_id { 1 }
    url { "https://canvas.instructure.com" }
  end

end
