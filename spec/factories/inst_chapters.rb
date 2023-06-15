# == Schema Information
#
# Table name: inst_chapters
#
#  id                      :bigint           not null, primary key
#  inst_book_id            :bigint           not null
#  name                    :string(100)      not null
#  short_display_name      :string(45)
#  position                :bigint
#  lms_chapter_id          :bigint
#  lms_assignment_group_id :bigint
#  created_at              :datetime
#  updated_at              :datetime
#
# Indexes
#
#  inst_chapters_inst_book_id_fk  (inst_book_id)
#

FactoryBot.define do
  factory :inst_chapter do
  end
end
