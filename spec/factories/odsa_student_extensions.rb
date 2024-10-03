# == Schema Information
#
# Table name: odsa_student_extensions
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  inst_section_id :integer          not null
#  soft_deadline   :datetime
#  hard_deadline   :datetime
#  created_at      :datetime
#  updated_at      :datetime
#  time_limit      :integer
#  opening_date    :datetime
#
# Indexes
#
#  odsa_student_extensions_inst_section_id_fk  (inst_section_id)
#  odsa_student_extensions_user_id_fk          (user_id)
#

FactoryBot.define do
  factory :odsa_student_extension do
  end
end
