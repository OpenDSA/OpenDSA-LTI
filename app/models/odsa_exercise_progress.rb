class OdsaExerciseProgress < ActiveRecord::Base
  #~ Relationships ............................................................
  belongs_to :inst_book_section_exercise
  belongs_to :inst_course_offering_exercise
  belongs_to :user

  #~ Validation ...............................................................
  validate :required_fields

  def required_fields
    if not(inst_book_section_exercise_id.present? or inst_course_offering_exercise_id.present?)
      errors.add(:inst_book_section_exercise_id, "or inst_course_offering_exercise_id must be present")
      errors.add(:inst_course_offering_exercise_id, "or inst_book_section_exercise_id must be present")
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
    elsif ex.lis_outcome_service_url != lis_outcome_service_url || ex.lis_result_sourcedid != lis_result_sourcedid

      ex.lis_outcome_service_url = lis_outcome_service_url
      ex.lis_result_sourcedid = lis_result_sourcedid
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
      if new_score == 100
        self.proficient_date = now
      end
    end
    self.first_done ||= now
    self.last_done = now
  end

  def post_course_offering_exercise_score_to_lms()
    if self.lis_outcome_service_url and self.lis_result_sourcedid
      ex = self.inst_course_offering_exercise
      lti_param = {
        "lis_outcome_service_url" => self.lis_outcome_service_url,
        "lis_result_sourcedid" => self.lis_result_sourcedid,
      }
      if self.lms_access_id.blank?
        lms_instance = self.inst_course_offering_exercise.course_offering.lms_instance
        tp = IMS::LTI::ToolProvider.new(lms_instance.consumer_key,
          lms_instance.consumer_secret,
          lti_param)
      else
        tp = IMS::LTI::ToolProvider.new(self.lms_access.consumer_key,
          self.lms_access.consumer_secret,
          lti_param)
      end
      tp.extend IMS::LTI::Extensions::OutcomeData::ToolProvider
      score = ex.points > 0 ? self.highest_score / ex.points : 1
      res = tp.post_extended_replace_result!(score: score)
      unless res.success?
        error = Error.new(:class_name => 'post_replace_result_fail',
                          :message => res.inspect,
                          :params => self.as_json.to_json)
        error.save!
      end
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
