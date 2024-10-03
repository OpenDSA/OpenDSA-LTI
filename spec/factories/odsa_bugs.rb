# == Schema Information
#
# Table name: odsa_bugs
#
#  id             :integer          not null, primary key
#  user_id        :integer          not null
#  os_family      :string(50)       not null
#  browser_family :string(20)       not null
#  title          :string(50)       not null
#  description    :text(4294967295) not null
#  screenshot     :string(100)
#  created_at     :datetime
#  updated_at     :datetime
#

FactoryBot.define do
  factory :odsa_bug do
  end
end
