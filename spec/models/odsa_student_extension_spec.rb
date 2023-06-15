# == Schema Information
#
# Table name: odsa_student_extensions
#
#  id              :bigint           not null, primary key
#  user_id         :bigint
#  inst_section_id :bigint           not null
#  soft_deadline   :datetime
#  hard_deadline   :datetime
#  created_at      :datetime
#  updated_at      :datetime
#  time_limit      :bigint
#  opening_date    :datetime
#
# Indexes
#
#  odsa_student_extensions_inst_section_id_fk  (inst_section_id)
#  odsa_student_extensions_user_id_fk          (user_id)
#
require 'rails_helper'

RSpec.describe OdsaStudentExtension, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
