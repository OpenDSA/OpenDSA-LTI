# == Schema Information
#
# Table name: odsa_exercise_attempts
#
#  id                               :integer          not null, primary key
#  user_id                          :integer          not null
#  inst_book_id                     :integer
#  inst_section_id                  :integer
#  inst_book_section_exercise_id    :integer
#  worth_credit                     :boolean          not null
#  time_done                        :datetime         not null
#  time_taken                       :integer          not null
#  count_hints                      :integer          not null
#  hint_used                        :boolean          not null
#  points_earned                    :decimal(5, 2)    not null
#  earned_proficiency               :boolean          not null
#  count_attempts                   :bigint           not null
#  ip_address                       :string(20)       not null
#  question_name                    :string(50)       not null
#  request_type                     :string(50)
#  created_at                       :datetime
#  updated_at                       :datetime
#  correct                          :boolean
#  pe_score                         :decimal(5, 2)
#  pe_steps_fixed                   :integer
#  inst_course_offering_exercise_id :integer
#  inst_module_section_exercise_id  :integer
#  answer                           :string(255)
#  question_id                      :integer
#  finished_frame                   :boolean
#
# Indexes
#
#  fk_rails_6944f2321b                                         (inst_module_section_exercise_id)
#  odsa_exercise_attempts_inst_book_id_fk                      (inst_book_id)
#  odsa_exercise_attempts_inst_book_section_exercise_id_fk     (inst_book_section_exercise_id)
#  odsa_exercise_attempts_inst_course_offering_exercise_id_fk  (inst_course_offering_exercise_id)
#  odsa_exercise_attempts_inst_section_id_fk                   (inst_section_id)
#  odsa_exercise_attempts_user_id_fk                           (user_id)
#
require 'rails_helper'

RSpec.describe OdsaExerciseAttempt, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
