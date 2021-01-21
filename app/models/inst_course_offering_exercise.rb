class InstCourseOfferingExercise < ApplicationRecord

  #~ Relationships ............................................................
  belongs_to :course_offering, inverse_of: :inst_course_offering_exercises
  belongs_to :inst_exercise
  has_many :odsa_user_interactions, dependent: :destroy
  has_many :odsa_exercise_attempts, dependent: :destroy
  has_many :odsa_exercise_progresses, dependent: :destroy

  #~ Validation ...............................................................
  #~ Constants ................................................................
  #~ Hooks ....................................................................
  #~ Class methods ............................................................

  def self.find_or_create_resource(course_offering_id, resource_link_id, resource_link_title, ex, settings)
    course_off_ex = InstCourseOfferingExercise.find_by(
      course_offering_id: course_offering_id,
      resource_link_id: resource_link_id,
      inst_exercise_id: ex.id,
    )
    if course_off_ex.blank?
      points = nil
      threshold = nil
      optionsJson = nil
      if settings.blank?
        points = 1
        threshold = ex.ex_type == 'ka' ? 5 : 1
        optionsJson = nil
      else
        points = settings.delete('points') || 1
        threshold = settings.delete('threshold')
        unless threshold
          threshold = ex.ex_type == 'ka' ? 5 : 1  
        end
        settings.delete('isGradable')
        settings.delete('required')
        optionsJson = settings.to_json
      end
      course_off_ex = InstCourseOfferingExercise.new(
        course_offering_id: course_offering_id,
        inst_exercise_id: ex.id,
        resource_link_id: resource_link_id,
        resource_link_title: resource_link_title,
        threshold: threshold,
        points: points,
        options: optionsJson,
      )
      course_off_ex.save!
    end
    return course_off_ex
  end

  def self.find_or_create(course_offering_id, inst_exercise_id, settings)
    points = settings.delete('points')
    threshold = settings.delete('threshold')
    optionsJson = settings.blank? ? nil : settings.to_json
    course_off_ex = InstCourseOfferingExercise.where(
      course_offering_id: course_offering_id,
      inst_exercise_id: inst_exercise_id,
      resource_link_id: nil,
    ).first
    if course_off_ex.blank?
      course_off_ex = InstCourseOfferingExercise.new(
        course_offering_id: course_offering_id,
        inst_exercise_id: inst_exercise_id,
        points: points,
        threshold: threshold,
        options: optionsJson,
      )
    else
      course_off_ex.points = points
      course_off_ex.threshold = threshold
      course_off_ex.options = optionsJson
    end
    course_off_ex.save!
    return course_off_ex
  end

  def self.find_and_update(id, resource_link_id, resource_link_title)
    ex = InstCourseOfferingExercise.includes(:inst_exercise).find(id)
    if ex.resource_link_id != resource_link_id || ex.resource_link_title != resource_link_title
      ex.resource_link_id = resource_link_id
      ex.resource_link_title = resource_link_title
      ex.save!
    end
    return ex
  end

  def self.handle_grade_passback(req, res, user_id, inst_course_offering_exercise_id)
    ex_progress = OdsaExerciseProgress.find_by(user_id: user_id,
      inst_course_offering_exercise_id: inst_course_offering_exercise_id)
    
    if req.replace_request?
      # set a new score for the user
            
      score = Float(req.score.to_s)

      if score < 0.0 || score > 1.0
        res.description = "The score must be between 0.0 and 1.0"
        res.code_major = 'failure'
      else
        # we store exercise scores in the database as an integer
        score = Integer(score * 100)
        if ex_progress.blank?
          ex_progress = OdsaExerciseProgress.new(user_id: user_id,
              inst_course_offering_exercise_id: inst_course_offering_exercise_id)
        end
        old_score = ex_progress.current_score
        ex_progress.update_score(score)
        lms_res = ex_progress.post_course_offering_exercise_score_to_lms()
        if lms_res.success?
          ex_progress.save!
          res.description = "Your old score of #{old_score} has been replaced with #{score}"
          res.code_major = 'success'
        else
          res.description = "Failed to transmit score"
          res.code_major = 'failure'
        end
      end
    elsif req.read_request?
      # return the score for the user
      res.description = ex_progress.blank? ? "Your score is 0" : "Your score is #{ex_progress.highest_score}"
      res.score = ex_progress.blank? ? 0 : ex_progress.highest_score
      res.code_major = 'success'
    end
    
    return res
  end

  #~ Instance methods .........................................................

  def build_av_address(base_address)
    if self.options.blank?
      return '/OpenDSA/' + base_address
    end
    require 'uri'
    query_string = '?' + URI.encode_www_form(JSON.parse(self.options))
    return '/OpenDSA/' + base_address + query_string
  end

  #~ Private instance methods .................................................
end
