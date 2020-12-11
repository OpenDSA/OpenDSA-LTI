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

  def self.to_csv
    #attributes = %w{user course question_name worth_credit time_done time_taken hint_used points_earned}

    CSV.generate(headers: true) do |csv|
      csv << all.first.attributes.map { |a,v| a }

      all.each do |progress|
        csv << progress.attributes.map { |a,v| v }
      end
    end
  end
  #~ Private instance methods .................................................


end
