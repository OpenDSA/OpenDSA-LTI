# == Schema Information
#
# Table name: terms
#
#  id         :bigint           not null, primary key
#  season     :bigint           not null
#  starts_on  :date             not null
#  ends_on    :date             not null
#  year       :bigint           not null
#  created_at :datetime
#  updated_at :datetime
#  slug       :string(255)      not null
#
# Indexes
#
#  index_terms_on_slug             (slug) UNIQUE
#  index_terms_on_starts_on        (starts_on)
#  index_terms_on_year_and_season  (year,season)
#

require 'spec_helper'

describe Term do
  pending "add some examples to (or delete) #{__FILE__}"
end
