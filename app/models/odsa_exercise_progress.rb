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
class OdsaExerciseProgress < ApplicationRecord
  #~ Relationships ............................................................
  belongs_to :inst_book_section_exercise
  belongs_to :inst_course_offering_exercise
  belongs_to :inst_module_section_exercise
  belongs_to :user
  belongs_to :lms_access

  #~ Validation ...............................................................
  validate :required_fields

  def required_fields
    if not(inst_book_section_exercise_id.present? or inst_course_offering_exercise_id.present? or inst_module_section_exercise_id.present?)
      errors.add(:base, "inst_book_section_exercise_id or inst_course_offering_exercise_id or inst_module_section_exercise_id must be present")
    end
  end

  #~ Constants ................................................................
  #~ Hooks ....................................................................
  after_initialize :set_defaults, unless: :persisted?
  #~ Class methods ............................................................

  def self.get_courseoffex_progress(user_id, inst_course_offering_exercise_id, lis_outcome_service_url, lis_result_sourcedid, lms_access_id)

    ex = OdsaExerciseProgress.find_by(user_id: user_id, inst_course_offering_exercise_id: inst_course_offering_exercise_id)
    if ex.blank?
      ex = OdsaExerciseProgress.new(
        user_id: user_id,
        inst_course_offering_exercise_id: inst_course_offering_exercise_id,
        lis_outcome_service_url: lis_outcome_service_url,
        lis_result_sourcedid: lis_result_sourcedid,
        lms_access_id: lms_access_id,
      )
      ex.save!
    elsif ex.lis_outcome_service_url != lis_outcome_service_url || ex.lis_result_sourcedid != lis_result_sourcedid || ex.lms_access_id != lms_access_id
      ex.lis_outcome_service_url = lis_outcome_service_url
      ex.lis_result_sourcedid = lis_result_sourcedid
      ex.lms_access_id = lms_access_id
      ex.save!
    end
    return ex
  end

  #~ Instance methods .........................................................
  def set_defaults
    self.current_score ||= 0
    self.highest_score ||= 0
    self.total_correct ||= 0
    self.total_worth_credit ||= 0
  end

  # update the current_score, highest_score, and proficient date
  def update_score(new_score)
    self.current_score = new_score
    now = DateTime.now
    if new_score > self.highest_score
      self.highest_score = new_score
      if new_score == 100    # FIXME: Shouldn't this use the threshold?
        self.proficient_date = now
      end
    end
    self.first_done ||= now
    self.last_done = now
  end

  def post_course_offering_exercise_score_to_lms()
    if self.lis_outcome_service_url and self.lis_result_sourcedid
      ex = self.inst_course_offering_exercise
      score = 0
      if self.highest_score >= ex.threshold
        score = 1
      end

      consumer_key = nil
      consumer_secret = nil
      if self.lms_access_id.blank?
        lms_instance = self.inst_course_offering_exercise.course_offering.lms_instance
        consumer_key = lms_instance.consumer_key
        consumer_secret = lms_instance.consumer_secret
      else
        consumer_key = self.lms_access.consumer_key
        consumer_secret = self.lms_access.consumer_secret
      end

      require 'lti/outcomes'
      res = LtiOutcomes.post_score_to_consumer(score,
                                               self.lis_outcome_service_url,
                                               self.lis_result_sourcedid,
                                               consumer_key,
                                               consumer_secret)
      return res
    end
  end

  def proficient?
    return ((self.proficient_date != nil) and self.proficient_date.year > 0)
  end

  def has_inst_course_offering_exercise?()
    return !self.inst_course_offering_exercise_id.blank?
  end

  #~ Private instance methods .................................................


end
