# == Schema Information
#
# Table name: student_extensions
#
#  id                     :bigint           not null, primary key
#  user_id                :integer
#  inst_chapter_module_id :integer
#  open_date              :datetime
#  close_date             :datetime
#  due_date               :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_student_extensions_on_inst_chapter_module_id  (inst_chapter_module_id)
#  index_student_extensions_on_user_id                 (user_id)
#
FactoryBot.define do
  factory :student_extension do
    
  end
end
