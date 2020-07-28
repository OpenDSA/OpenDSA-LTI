# == Schema Information
#
# Table name: course_offerings
#
#  id                      :integer          not null, primary key
#  course_id               :integer          not null
#  term_id                 :integer          not null
#  label                   :string(255)      default(""), not null
#  url                     :string(255)
#  self_enrollment_allowed :boolean
#  created_at              :datetime
#  updated_at              :datetime
#  cutoff_date             :date
#
# Indexes
#
#  index_course_offerings_on_course_id  (course_id)
#  index_course_offerings_on_term_id    (term_id)
#

# =============================================================================
# Represents a single section (or offering) of a course in a specific term.
#
class CourseOffering < ApplicationRecord

  #~ Relationships ............................................................

  belongs_to :lms_instance, inverse_of: :course_offerings
  belongs_to :course, inverse_of: :course_offerings
  belongs_to :term, inverse_of: :course_offerings
  belongs_to :late_policy, inverse_of: :course_offerings

  has_many :inst_books, inverse_of: :course_offering, dependent: :destroy
  has_many :inst_course_offering_exercises, inverse_of: :course_offering, dependent: :destroy
  has_many :inst_module_versions, inverse_of: :course_offering, dependent: :destroy
  accepts_nested_attributes_for :inst_books, allow_destroy: true

  has_many :course_enrollments,
    -> { includes(:course_role, :user).order(
      'course_roles.id ASC', 'users.last_name ASC', 'users.first_name ASC') },
    inverse_of: :course_offering,
    dependent: :destroy
  has_many :users, through: :course_enrollments

  accepts_nested_attributes_for :term

  scope :active, -> { where(archived: false) }

  scope :by_date,
    -> { includes(:term).order('terms.starts_on DESC', 'label ASC') }

  scope :managed_by_user, -> (u) {
    joins(:course_enrollments).
        where {course_enrollments.user == u &&
    course_enrollments.course_role_id == CourseRole::INSTRUCTOR_ID }
  }


  #~ Validation ...............................................................

  validates :label, presence: true
  validates :course, presence: true
  validates :term, presence: true

  #~ Hooks ....................................................................
  after_save :update_inst_book

  def update_inst_book
    inst_books.each do |inst_book|
      inst_book.last_compiled = nil
      inst_book.save
    end
  end

  #~ Class Methods ............................................................

  def self.ensure_exists(lms_instance_id, organization_id, lms_course_num, lms_course_code, course_name)
    course_offering = CourseOffering.find_by(lms_instance_id: lms_instance_id,
                                             lms_course_num: lms_course_num)
    if course_offering.blank?
      if organization_id.blank?
        return nil
      end
      course = Course.find_by(number: lms_course_code,
                              organization_id: organization_id)
      if course.blank?
        course = Course.new(
          name: course_name,
          number: lms_course_code,
          organization_id: organization_id,
          user_id: current_user.id,
        )
        course.save
      end
      course_offering = CourseOffering.new(
        course: course,
        term: Term.current_or_next_term,
        label: lms_course_code,
        lms_instance_id: lms_instance_id,
        lms_course_code: lms_course_code,
        lms_course_num: lms_course_num,
      )
      course_offering.save
    end
    return course_offering
  end


  #~ Public instance methods ..................................................

  # -------------------------------------------------------------

  def admin_display_name
    "#{course.organization.abbreviation} #{term.slug} #{course.number} (#{label})"
  end

  def display_name
    "#{course.organization.abbreviation} #{term.slug} #{course.number} (#{label})"
  end

  def name
    self.course.name + ' - ' + self.term.display_name
  end


  # -------------------------------------------------------------
  def display_name_with_term
    "#{course.number} (#{term.display_name}, #{label})"
  end


  # -------------------------------------------------------------
  # Public: Gets a relation representing all Users who are allowed to
  # manage this CourseOffering.
  #
  def managers
    course_enrollments.where(course_roles: { can_manage_course: true }).
      map(&:user)
  end


  # -------------------------------------------------------------
  # Public: Gets a relation representing all Users who are students in
  # this CourseOffering.
  #
  def students
    course_enrollments.where(course_role: CourseRole.student).map(&:user)
  end


  def students_count
    course_enrollments.where(course_role: CourseRole.student).count
  end


  # -------------------------------------------------------------
  # Public: Gets all inst_books used in this CourseOffering.
  #
  def odsa_books
    inst_books
  end


  # -------------------------------------------------------------
  # Public: Gets a relation representing all Users who are instructors in
  # this CourseOffering.
  #
  def instructors
    course_enrollments.where(course_role: CourseRole.instructor).map(&:user)
  end


  # -------------------------------------------------------------
  def effective_cutoff_date
    # if no cutoff date is set, then always allow enrollment
    self.cutoff_date || (Time.now + 1.years) #self.term.ends_on
  end


  # -------------------------------------------------------------
  # Public: Returns a boolean indicating whether the offering is
  # currently available for self-enrollment
  def can_enroll?
    self.self_enrollment_allowed && effective_cutoff_date >= Time.now
  end


  # -------------------------------------------------------------
  # Public: Gets a relation representing all Users who are graders in
  # this CourseOffering.
  #
  def graders
    course_enrollments.where(course_role: CourseRole.grader).map(&:user)
  end


  # -------------------------------------------------------------
  def other_concurrent_offerings
    course.course_offerings.where(term: term, course: course)
  end


  # -------------------------------------------------------------
  def is_enrolled?(user)
    user && users.include?(user)
  end


  # -------------------------------------------------------------
  def is_manager?(user)
    role_for_user(user).andand.can_manage_course?
  end


  # -------------------------------------------------------------
  def is_instructor?(user)
    role_for_user(user).andand.is_instructor?
  end


  # -------------------------------------------------------------
  def is_grader?(user)
    role_for_user(user).andand.is_grader?
  end


  # -------------------------------------------------------------
  def is_staff?(user)
    role_for_user(user).andand.is_staff?
  end

  # -------------------------------------------------------------
  def is_student?(user)
    role_for_user(user).andand.is_student?
  end

  # -------------------------------------------------------------
  def role_for_user(user)
    user && course_enrollments.where(user: user).first.andand.course_role
  end

end
