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
require 'rails_helper'

RSpec.describe InstChapter, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
