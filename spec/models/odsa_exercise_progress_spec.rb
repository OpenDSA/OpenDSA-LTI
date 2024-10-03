# == Schema Information
#
# Table name: odsa_exercise_progresses
#
#  id                               :integer          not null, primary key
#  user_id                          :integer          not null
#  inst_book_section_exercise_id    :integer
#  current_score                    :integer          not null
#  highest_score                    :integer          not null
#  first_done                       :datetime         not null
#  last_done                        :datetime         not null
#  total_correct                    :integer          not null
#  total_worth_credit               :integer          not null
#  proficient_date                  :datetime         not null
#  current_exercise                 :string(255)
#  correct_exercises                :string(255)
#  hinted_exercise                  :string(255)
#  created_at                       :datetime
#  updated_at                       :datetime
#  inst_course_offering_exercise_id :integer
#  lis_outcome_service_url          :string(255)
#  lis_result_sourcedid             :string(255)
#  lms_access_id                    :integer
#  inst_module_section_exercise_id  :integer
#
# Indexes
#
#  fk_rails_3327f6b532                                           (lms_access_id)
#  fk_rails_7b1bb7d31f                                           (inst_module_section_exercise_id)
#  index_odsa_ex_prog_on_user_id_and_inst_bk_sec_ex_id           (user_id,inst_book_section_exercise_id) UNIQUE
#  index_odsa_ex_prog_on_user_module_sec_ex                      (user_id,inst_module_section_exercise_id) UNIQUE
#  index_odsa_exercise_prog_on_user_course_offering_exercise     (user_id,inst_course_offering_exercise_id) UNIQUE
#  odsa_exercise_progresses_inst_book_section_exercise_id_fk     (inst_book_section_exercise_id)
#  odsa_exercise_progresses_inst_course_offering_exercise_id_fk  (inst_course_offering_exercise_id)
#
require 'rails_helper'

RSpec.describe OdsaExerciseProgress, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
