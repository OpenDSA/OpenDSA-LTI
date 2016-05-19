class CourseOffering < ActiveRecord::Base
  self.table_name = 'course_offerings'
  self.inheritance_column = 'ruby_type'
  self.primary_key = 'id'

  if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
    attr_accessible :course_id, :term_id, :late_policy_id, :label, :url, :self_enrollment_allowed, :created_at, :updated_at, :cutoff_date, :lms_course_code, :lms_course_id
  end

  belongs_to :course, :foreign_key => 'course_id', :class_name => 'Course'
  belongs_to :late_policy, :foreign_key => 'late_policy_id', :class_name => 'LatePolicy'
  belongs_to :term, :foreign_key => 'term_id', :class_name => 'Term'
  has_many :course_enrollments, :foreign_key => 'course_offering_id', :class_name => 'CourseEnrollment'
  has_many :inst_books, :foreign_key => 'course_offering_id', :class_name => 'InstBook'
  has_many :course_roles, :through => :course_enrollments, :foreign_key => 'course_role_id', :class_name => 'CourseRole'
  has_many :users, :through => :course_enrollments, :foreign_key => 'user_id', :class_name => 'User'
  has_many :inst_book_owners, :through => :inst_books, :foreign_key => 'inst_book_owner_id', :class_name => 'InstBookOwner'

#~ Validation ...............................................................

  validates :label, presence: true
  validates :course, presence: true
  validates :term, presence: true


  #~ Public instance methods ..................................................

  # -------------------------------------------------------------
  def display_name
    "#{course.number} (#{label})"
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


  # -------------------------------------------------------------
  # Public: Gets a relation representing all Users who are instructors in
  # this CourseOffering.
  #
  def instructors
    course_enrollments.where(course_role: CourseRole.instructor).map(&:user)
  end


  # -------------------------------------------------------------
  def effective_cutoff_date
    self.cutoff_date || self.term.ends_on
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
