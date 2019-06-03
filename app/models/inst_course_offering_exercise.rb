class InstCourseOfferingExercise < ActiveRecord::Base

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
    )
    if course_off_ex.blank?
      points = nil
      threshold = nil
      optionsJson = nil
      if settings.blank?
        points = 1
        threshold = ex.threshold
        optionsJson = nil
      else
        points = settings.delete('points') || 1
        threshold = settings.delete('threshold') || ex.threshold
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

  #~ Instance methods .........................................................

  def build_av_address(base_address)
    if self.options.blank?
      return base_address
    end
    require 'uri'
    query_string = '?' + URI.encode_www_form(JSON.parse(self.options))
    return base_address + query_string
  end

  #~ Private instance methods .................................................
end
