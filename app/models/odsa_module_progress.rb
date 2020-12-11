class OdsaModuleProgress < ApplicationRecord
  #~ Relationships ............................................................
  belongs_to :user
  belongs_to :inst_book
  belongs_to :inst_chapter_module
  belongs_to :inst_module_version
  belongs_to :lms_access

  #~ Validation ...............................................................
  validate :required_fields

  def required_fields
    if not(inst_book_id.present? or inst_module_version_id.present?)
      errors.add(:base, "inst_book_id or inst_module_version_id must be present")
    end
  end

  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................

  def self.get_progress(user_id, inst_chapter_module_id, inst_book_id, lis_outcome_service_url = nil, lis_result_sourcedid = nil, lms_access_id = nil)
    module_progress = OdsaModuleProgress.find_by(user_id: user_id, inst_chapter_module_id: inst_chapter_module_id)
    if module_progress == nil
      module_progress = OdsaModuleProgress.new(user_id: user_id, inst_book_id: inst_book_id,
                                               inst_chapter_module_id: inst_chapter_module_id)
      unless lis_outcome_service_url == nil or lis_result_sourcedid == nil or lms_access_id == nil
        module_progress.lis_outcome_service_url = lis_outcome_service_url
        module_progress.lis_result_sourcedid = lis_result_sourcedid
        module_progress.lms_access_id = lms_access_id
      end
      module_progress.save!
    elsif (lis_outcome_service_url != nil and module_progress.lis_outcome_service_url == nil) or (lis_result_sourcedid != nil and module_progress.lis_result_sourcedid == nil) or (lms_access_id != nil and module_progress.lms_access_id == nil)
      module_progress.lis_outcome_service_url = lis_outcome_service_url
      module_progress.lis_result_sourcedid = lis_result_sourcedid
      module_progress.lms_access_id = lms_access_id
      module_progress.save!
    end
    module_progress
  end

  def self.get_standalone_progress(user_id, inst_module_version_id, lis_outcome_service_url = nil, lis_result_sourcedid = nil, lms_access_id = nil)
    module_progress = OdsaModuleProgress.find_by(user_id: user_id, inst_module_version_id: inst_module_version_id)
    if module_progress == nil
      module_progress = OdsaModuleProgress.new(user_id: user_id, inst_module_version_id: inst_module_version_id)
      unless lis_outcome_service_url == nil or lis_result_sourcedid == nil
        module_progress.lis_outcome_service_url = lis_outcome_service_url
        module_progress.lis_result_sourcedid = lis_result_sourcedid
        module_progress.lms_access_id = lms_access_id
      end
      module_progress.save!
    elsif (lis_outcome_service_url != nil and module_progress.lis_outcome_service_url == nil) or (lis_result_sourcedid != nil and module_progress.lis_result_sourcedid == nil) or (lms_access_id != nil and module_progress.lms_access_id == nil)
      module_progress.lis_outcome_service_url = lis_outcome_service_url
      module_progress.lis_result_sourcedid = lis_result_sourcedid
      module_progress.lms_access_id = lms_access_id
      module_progress.save!
    end
    module_progress
  end

  #~ Instance methods .........................................................
  def update_proficiency(inst_exercise)
    if self.inst_module_version_id
      # standalone module
      return update_standalone_proficiency(inst_exercise)
    end

    book_progress = OdsaBookProgress.get_progress(self.user_id, self.inst_book_id)
    # TODO: This only gets progresses for exercises that have been attempted at least once
    bk_sec_exs = self.inst_chapter_module.get_bk_sec_exercises() || []
    module_exercises = bk_sec_exs.collect { |ex| ex.inst_exercise.short_name } || []
    proficient_exercises = book_progress.get_proficient_exercises || []

    self.first_done ||= DateTime.now
    self.last_done = DateTime.now
    old_score = self.highest_score
    update_score(bk_sec_exs)

    # Comparing two floats.
    # Only send score to LMS if the score has increased.
    if (self.highest_score - old_score).abs > 0.001
      res = post_score_to_lms()
      unless res.blank?
        # res will be null if this module isn't linked to an LMS assignment
        unless res.success?
          # Failed to post score to LMS.
          # Keep old score so that if the student attempts the exercise again
          # we will try to send the new score again.
          self.highest_score = old_score
        end
      end
    end
    self.save!

    last_exercise = false
    if self.proficient_date.nil?
      if module_exercises and proficient_exercises
        if (module_exercises - proficient_exercises).length == 1
          if module_exercises[0] == inst_exercise.short_name
            last_exercise = true
          end
        end
        if (module_exercises - proficient_exercises).empty? or last_exercise
          self.proficient_date = DateTime.now
          self.save!
          return true
        else
          return false
        end
      else
        return false
      end
    else
      return true
    end
  end

  def post_score_to_lms()
    if self.lis_outcome_service_url and self.lis_result_sourcedid

      consumer_key = nil
      consumer_secret = nil
      if self.lms_access_id.blank?
        lms_instance = self.inst_module_version.course_offering.lms_instance
        consumer_key = lms_instance.consumer_key
        consumer_secret = lms_instance.consumer_secret
      else
        consumer_key = self.lms_access.consumer_key
        consumer_secret = self.lms_access.consumer_secret
      end

      require 'lti/outcomes'
      res = LtiOutcomes.post_score_to_consumer(self.highest_score, 
                                               self.lis_outcome_service_url,
                                               self.lis_result_sourcedid,
                                               consumer_key,
                                               consumer_secret)
      return res
    end
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
  private

  # compute the aggregate score from all of the exercises in the module
  def update_score(bk_sec_exs)
    exercise_progresses = self.inst_chapter_module.get_exercise_progresses(self.user_id)
    score = 0
    total_points = 0
    bk_sec_exs.each do |ex|
      total_points += ex.points
      prog = exercise_progresses.detect { |p| p.inst_book_section_exercise_id == ex.id }
      if !prog.blank? and prog.proficient?
        score += ex.points
      end
    end
    if (total_points == 0)
      self.current_score = 0
    else
      self.current_score = score / total_points
    end
    if self.highest_score.nil?
      self.highest_score = 0
    end
    if self.current_score > self.highest_score
      self.highest_score = self.current_score
    end

    self.current_score
  end

  def update_standalone_proficiency(inst_module_section_exercise)
    # find all exercises in the module
    # find exercises the user has achieved proficiency on
    
    mod_sec_exs = self.inst_module_version.inst_module_section_exercises || []
    module_exercises = mod_sec_exs.collect { |ex| ex.id } || []
    exercise_progresses = OdsaExerciseProgress.joins(:inst_module_section_exercise)
      .where("inst_module_section_exercises.inst_module_version_id = #{self.inst_module_version_id} AND user_id = #{self.user_id}")
    proficient_exercises = exercise_progresses.select{ |ep| ep.proficient? }
                                              .collect{ |ep| ep.inst_module_section_exercise_id } || [] 

    self.first_done ||= DateTime.now
    self.last_done = DateTime.now
    old_score = self.highest_score
    update_standalone_score(mod_sec_exs, exercise_progresses)

    # Comparing two floats.
    # Only send score to LMS if the score has increased.
    if (self.highest_score - old_score).abs > 0.001
      res = post_score_to_lms()
      unless res.blank?
        # res will be null if this module isn't linked to an LMS assignment
        unless res.success?
          # Failed to post score to LMS.
          # Keep old score so that if the student attempts the exercise again
          # we will try to send the new score again.
          self.highest_score = old_score
        end
      end
    end
    self.save!

    last_exercise = false
    if self.proficient_date.nil?
      if module_exercises and proficient_exercises
        if (module_exercises - proficient_exercises).length == 1
          if module_exercises[0] == inst_module_section_exercise.id
            last_exercise = true
          end
        end
        if (module_exercises - proficient_exercises).empty? or last_exercise
          self.proficient_date = DateTime.now
          self.save!
          return true
        else
          return false
        end
      else
        return false
      end
    else
      return true
    end
  end

  def update_standalone_score(mod_sec_exs, exercise_progresses)
    score = 0
    total_points = 0
    mod_sec_exs.each do |ex|
      total_points += ex.points
      prog = exercise_progresses.detect { |p| p.inst_module_section_exercise_id == ex.id }
      if !prog.blank? and prog.proficient?
        score += ex.points
      end
    end
    if (total_points == 0)
      self.current_score = 0
    else
      self.current_score = score / total_points
    end
    if self.highest_score.nil?
      self.highest_score = 0
    end
    if self.current_score > self.highest_score
      self.highest_score = self.current_score
    end

    self.current_score
  end

end
