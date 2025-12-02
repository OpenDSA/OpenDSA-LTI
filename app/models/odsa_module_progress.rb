# == Schema Information
#
# Table name: odsa_module_progresses
#
#  id                      :bigint           not null, primary key
#  user_id                 :bigint           not null
#  inst_book_id            :bigint
#  first_done              :datetime         not null
#  last_done               :datetime         not null
#  proficient_date         :datetime         not null
#  created_at              :datetime
#  updated_at              :datetime
#  inst_chapter_module_id  :bigint
#  lis_outcome_service_url :string(255)
#  lis_result_sourcedid    :string(255)
#  current_score           :float(24)        not null
#  highest_score           :float(24)        not null
#  lms_access_id           :bigint
#  inst_module_version_id  :bigint
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
    module_progress = OdsaModuleProgress.find_or_initialize_by(user_id: user_id, inst_chapter_module_id: inst_chapter_module_id)
    if module_progress.new_record?
      module_progress.inst_book_id = inst_book_id
      module_progress.lis_outcome_service_url = lis_outcome_service_url
      module_progress.lis_result_sourcedid = lis_result_sourcedid
      module_progress.lms_access_id = lms_access_id
      module_progress.save!
    elsif lis_outcome_service_url.present? && module_progress.lis_outcome_service_url != lis_outcome_service_url
      module_progress.lis_outcome_service_url = lis_outcome_service_url
      module_progress.lis_result_sourcedid = lis_result_sourcedid
      module_progress.lms_access_id = lms_access_id
      module_progress.save!
    end

    module_progress
  end

  def self.get_standalone_progress(user_id, inst_module_version_id, lis_outcome_service_url = nil, lis_result_sourcedid = nil, lms_access_id = nil)
    module_progress = OdsaModuleProgress.find_or_initialize_by(user_id: user_id, inst_module_version_id: inst_module_version_id)
    if module_progress.new_record?
      module_progress.lis_outcome_service_url = lis_outcome_service_url
      module_progress.lis_result_sourcedid = lis_result_sourcedid
      module_progress.lms_access_id = lms_access_id
      module_progress.save!
    elsif lis_outcome_service_url.present? && module_progress.lis_outcome_service_url != lis_outcome_service_url
      module_progress.lis_outcome_service_url = lis_outcome_service_url
      module_progress.lis_result_sourcedid = lis_result_sourcedid
      module_progress.lms_access_id = lms_access_id
      module_progress.save!
    end
    module_progress
  end

  #~ Instance methods .........................................................
  def update_proficiency(inst_exercise, force_send = false)
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
    # Only send score to LMS if the score has increased, or previous
    # passback was not performed or unsuccessful
    # if force_send or
    #   self.last_passback.nil? or
    #   (self.inst_book && self.inst_book.last_compiled.nil?) or
    #   (self.last_passback && self.inst_book && self.inst_book.last_compiled && (self.last_passback < self.inst_book.last_compiled)) or
    #   self.highest_score > old_score
    #   res = post_score_to_lms()
    # end
    res = post_score_to_lms()
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
      lms_instance = nil

      if self.lms_access_id.blank?
        if self.inst_module_version
          lms_instance = self.inst_module_version.course_offering&.lms_instance
        elsif self.inst_book
          lms_instance = self.inst_book.course_offering&.lms_instance
        end

        if lms_instance
          consumer_key = lms_instance.consumer_key
          consumer_secret = lms_instance.consumer_secret
        else
          return { error: "LMS instance not found", status: :internal_server_error }
        end
      else
        consumer_key = self.lms_access.consumer_key
        consumer_secret = self.lms_access.consumer_secret
        lms_instance = self.lms_access.lms_instance
      end

      # LTI 1.3 flow
      if lms_instance&.lti_version == 'LTI-1p3'
        return post_score_to_lti_13(lms_instance)
      else
        # LTI 1.1 flow
        require 'lti/outcomes'
        res = LtiOutcomes.post_score_to_consumer(self.highest_score,
                                                 self.lis_outcome_service_url,
                                                 self.lis_result_sourcedid,
                                                 consumer_key,
                                                 consumer_secret)
        if res.success?
          self.last_passback = self.last_done
        else
          # passback failed, so clear timestamp of last successful passback
          self.last_passback = nil
        end
        return res
      end
    else
      # Passback not attempted, so clear timestamp of last successful passback
      self.last_passback = nil
      # explicitly set return value to indicate no passback happened
      return nil
    end
  end

  def post_score_to_lti_13(lms_instance)
    begin
      lti_launch = LtiLaunch.where(user_id: self.user_id, lms_instance_id: lms_instance.id).order(created_at: :desc).first

      if lti_launch.nil?
        return { error: "No LTI Launch found", status: :not_found }
      end

      access_token_response = Lti13Service::GetAgsAccessToken.new(lms_instance).call
      access_token = access_token_response['access_token']

      response = Lti13::ServicesController.new.send_score(
        launch_id: lms_instance.id,
        access_token: access_token,
        platform_jwt: lti_launch.id_token,  # id_token from LtiLaunch
        kid: lti_launch.kid,  # kid from LtiLaunch
        highest_score: self.highest_score
      )

      if response[:status] == :ok || response[:status] == 200
        self.last_passback = self.last_done
      else
        self.last_passback = nil
      end

      return response
    rescue => e
      self.last_passback = nil
      return { error: e.message, status: :internal_server_error }
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
      if !prog.blank?
        if prog.proficient?
          score += ex.points
        elsif ex.partial_credit
          score += ex.points * prog.highest_score / 100.0
        end
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
    if self.last_passback.nil? or
      self.highest_score > old_score

      res = post_score_to_lms()
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
      if !prog.blank?
        if prog.proficient?
          score += ex.points
        elsif ex.partial_credit
          score += ex.points * prog.highest_score / 100.0
        end
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
