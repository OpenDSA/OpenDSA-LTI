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

  def self.find_or_create_resource(course_offering_id, resource_link_id, resource_link_title, ex)
    course_off_ex = InstCourseOfferingExercise.find_by(
      course_offering_id: course_offering.id,
      resource_link_id: resource_link_id,
    )
    if course_off_ex.blank?
      course_off_ex = InstCourseOfferingExercise.new(
        course_offering: course_offering,
        inst_exercise_id: ex.id,
        resource_link_id: resource_link_id,
        resource_link_title: resource_link_title,
        threshold: ex.threshold,
      )
      course_off_ex.save!
    end
    return course_off_ex
  end

  def self.find_or_create(course_offering_id, inst_exercise_id, settings)
    points = settings.delete('points')
    threshold = settings.delete('threshold')
    optionsJson = settings.to_json
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
        options: optionsJson
      )
    else
      course_off_ex.points = points
      course_off_ex.threshold = threshold
      course_off_ex.options = optionsJson
    end
    course_off_ex.save!
    return course_off_ex
  end

  #~ Instance methods .........................................................
  #~ Private instance methods .................................................
end