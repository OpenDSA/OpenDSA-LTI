# == Schema Information
#
# Table name: inst_book_section_exercises
#
#  id               :bigint           not null, primary key
#  inst_book_id     :bigint           not null
#  inst_section_id  :bigint           not null
#  inst_exercise_id :bigint
#  points           :decimal(5, 2)    not null
#  required         :boolean          default(FALSE)
#  threshold        :decimal(5, 2)    not null
#  created_at       :datetime
#  updated_at       :datetime
#  type             :boolean
#  options          :text(4294967295)
#
# Indexes
#
#  inst_book_section_exercises_inst_book_id_fk      (inst_book_id)
#  inst_book_section_exercises_inst_exercise_id_fk  (inst_exercise_id)
#  inst_book_section_exercises_inst_section_id_fk   (inst_section_id)
#
require 'rails_helper'

RSpec.describe InstBookSectionExercise, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
