# == Schema Information
#
# Table name: odsa_module_progresses
#
#  id                      :integer          not null, primary key
#  user_id                 :integer          not null
#  inst_book_id            :integer
#  first_done              :datetime         not null
#  last_done               :datetime         not null
#  proficient_date         :datetime         not null
#  created_at              :datetime
#  updated_at              :datetime
#  inst_chapter_module_id  :integer
#  lis_outcome_service_url :string(255)
#  lis_result_sourcedid    :string(255)
#  current_score           :float(24)        not null
#  highest_score           :float(24)        not null
#  lms_access_id           :integer
#  inst_module_version_id  :integer
#  last_passback           :datetime         not null
#
# Indexes
#
#  fk_rails_38a9ac7560                               (inst_module_version_id)
#  index_odsa_mod_prog_on_user_mod_version           (user_id,inst_module_version_id) UNIQUE
#  index_odsa_module_progress_on_user_and_module     (user_id,inst_chapter_module_id) UNIQUE
#  odsa_module_progresses_inst_book_id_fk            (inst_book_id)
#  odsa_module_progresses_inst_chapter_module_id_fk  (inst_chapter_module_id)
#  odsa_module_progresses_lms_access_id_fk           (lms_access_id)
#

FactoryBot.define do
  factory :odsa_module_progress do
  end
end
