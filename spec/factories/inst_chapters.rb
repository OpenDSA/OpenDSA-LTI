# == Schema Information
#
# Table name: inst_chapters
#
#  id                      :integer          not null, primary key
#  inst_book_id            :integer          not null
#  name                    :string(100)      not null
#  short_display_name      :string(45)
#  position                :integer
#  lms_chapter_id          :integer
#  lms_assignment_group_id :integer
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
