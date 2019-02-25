class OdsaModuleProgress < ActiveRecord::Base
  #~ Relationships ............................................................
  belongs_to :user
  belongs_to :inst_book
  belongs_to :inst_chapter_module
  belongs_to :lms_access

  #~ Validation ...............................................................
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

  #~ Instance methods .........................................................
  def update_proficiency(inst_exercise)
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
      lti_param = {
        "lis_outcome_service_url" => self.lis_outcome_service_url,
        "lis_result_sourcedid" => self.lis_result_sourcedid,
      }
      tp = IMS::LTI::ToolProvider.new(self.lms_access.consumer_key,
                                      self.lms_access.consumer_secret,
                                      lti_param)
      tp.extend IMS::LTI::Extensions::OutcomeData::ToolProvider

      res = tp.post_extended_replace_result!(score: self.highest_score)
      unless res.success?
        error = Error.new(:class_name => 'post_replace_result_fail',
                          :message => res.inspect,
                          :params => self.as_json.to_json)
        error.save!
      end
      return res
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
end
