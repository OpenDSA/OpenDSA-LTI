class User < ActiveRecord::Base
  include Gravtastic
  gravtastic secure: true, default: 'monsterid'

  extend FriendlyId
  friendly_id :email_or_id, use: :slugged

  enum role: [:user, :vip, :admin]
  after_initialize :set_default_role, :if => :new_record?

  def set_default_role
    self.role ||= :user
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

    self.table_name = 'users'
    self.inheritance_column = 'ruby_type'
    self.primary_key = 'id'

    if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
      attr_accessible :time_zone_id, :email, :encrypted_password, :reset_password_token, :reset_password_sent_at, :remember_created_at, :sign_in_count, :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip, :last_sign_in_ip, :confirmation_token, :confirmed_at, :confirmation_sent_at, :created_at, :updated_at, :first_name, :last_name, :global_role_id, :avatar, :slug
    end

    belongs_to :global_role, :foreign_key => 'global_role_id', :class_name => 'GlobalRole'
    belongs_to :time_zone, :foreign_key => 'time_zone_id', :class_name => 'TimeZone'
    has_many :course_enrollments, :foreign_key => 'user_id', :class_name => 'CourseEnrollment'
    has_many :inst_book_owners, :foreign_key => 'user_id', :class_name => 'InstBookOwner'
    has_many :lms_accesses, :foreign_key => 'user_id', :class_name => 'LmsAccess'
    has_many :odsa_book_progresses, :foreign_key => 'user_id', :class_name => 'OdsaBookProgress'
    has_many :odsa_bugs, :foreign_key => 'user_id', :class_name => 'OdsaBug'
    has_many :odsa_exercise_attempts, :foreign_key => 'user_id', :class_name => 'OdsaExerciseAttempt'
    has_many :odsa_exercise_progresses, :foreign_key => 'user_id', :class_name => 'OdsaExerciseProgress'
    has_many :odsa_module_progresses, :foreign_key => 'user_id', :class_name => 'OdsaModuleProgress'
    has_many :odsa_student_extensions, :foreign_key => 'user_id', :class_name => 'OdsaStudentExtension'
    has_many :odsa_user_interactions, :foreign_key => 'user_id', :class_name => 'OdsaUserInteraction'
    has_many :course_offerings, :through => :course_enrollments, :foreign_key => 'course_offering_id', :class_name => 'CourseOffering'
    has_many :course_roles, :through => :course_enrollments, :foreign_key => 'course_role_id', :class_name => 'CourseRole'
    has_many :book_roles, :through => :inst_book_owners, :foreign_key => 'book_role_id', :class_name => 'BookRole'
    has_many :lms_instances, :through => :lms_accesses, :foreign_key => 'lms_instance_id', :class_name => 'LmsInstance'
    has_many :inst_book_section_exercises_by_odsa_exercise_attempts, :source => :inst_book_section_exercise, :through => :odsa_exercise_attempts, :foreign_key => 'inst_book_section_exercise_id', :class_name => 'InstBookSectionExercise'
    has_many :inst_book_section_exercises_by_odsa_exercise_progress, :source => :inst_book_section_exercise, :through => :odsa_exercise_progresses, :foreign_key => 'inst_book_section_exercise_id', :class_name => 'InstBookSectionExercise'
    has_many :inst_books_by_odsa_module_progress, :source => :inst_book, :through => :odsa_module_progresses, :foreign_key => 'inst_book_id', :class_name => 'InstBook'
    has_many :inst_sections_by_odsa_student_extensions, :source => :inst_section, :through => :odsa_student_extensions, :foreign_key => 'inst_section_id', :class_name => 'InstSection'
    has_many :inst_book_section_exercises_by_odsa_user_interactions, :source => :inst_book_section_exercise, :through => :odsa_user_interactions, :foreign_key => 'inst_book_section_exercise_id', :class_name => 'InstBookSectionExercise'
    has_many :inst_books_by_odsa_user_interactions, :source => :inst_book, :through => :odsa_user_interactions, :foreign_key => 'inst_book_id', :class_name => 'InstBook'
    has_many :inst_sections_by_odsa_user_interactions, :source => :inst_section, :through => :odsa_user_interactions, :foreign_key => 'inst_section_id', :class_name => 'InstSection'

  before_create :set_default_global_role

  paginates_per 100

  # scope :search, lambda { |query|
  #   unless query.blank?
  #     arel = self.arel_table
  #     pattern = "%#{query}%"
  #     where(arel[:email].matches(pattern).or(
  #           arel[:last_name].matches(pattern)).or(
  #           arel[:last_name].matches(pattern)))
  #   end
  # }

  scope :alphabetical, -> { order('last_name asc, first_name asc, email asc') }
  scope :visible_to_user, -> (u) { joins{course_enrollments.outer}.
    where{ (id == u.id) |
    (course_enrollments.course_role_id != CourseRole::STUDENT_ID) } }


  #~ Class methods ............................................................

  # -------------------------------------------------------------
  def self.all_emails(prefix = '')
    self.uniq.where(self.arel_table[:email].matches(
      "#{prefix}%")).reorder('email asc').pluck(:email)
  end


  #~ Instance methods .........................................................

  # -------------------------------------------------------------
  #  def storage_path
  #    File.join(
  #    SystemConfiguration.first.storage_path, 'users', email)
  #  end


  # -------------------------------------------------------------
  def ability
    @ability ||= Ability.new(self)
  end


  # -------------------------------------------------------------
  # Public: Gets a relation representing all of the CourseOfferings that
  # this user can manage.
  #
  # Returns a relation representing all of the CourseOfferings that this
  # user can manage
  #
  def managed_course_offerings
    course_enrollments.where(course_roles: { can_manage_course: true }).
      map(&:course_offering)
  end


  # -------------------------------------------------------------
  def instructor_course_offerings
    course_enrollments.where(course_role: CourseRole.instructor).
      map(&:course_offering)
  end


  # -------------------------------------------------------------
  def grader_course_offerings
    course_enrollments.where(course_role: CourseRole.grader).
      map(&:course_offering)
  end


  # -------------------------------------------------------------
  def student_course_offerings
    course_enrollments.where(course_role: CourseRole.student).
      map(&:course_offering)
  end


  # -------------------------------------------------------------
  def course_offerings_for_term(term, course)
    conditions = { term: term, 'users.id' => self }
    if course
      conditions[:course] = course
    end
    CourseOffering.
      joins(course_enrollments: :user).
      where(conditions).
      distinct
  end


  # -------------------------------------------------------------
  def courses_for_term(term)
    Course.
      joins(course_offerings: { course_enrollments: :user }).
      where('course_offerings.term_id' => term, 'users.id' => self).
      distinct
  end


  # -------------------------------------------------------------
  # Gets the user's "display name", which is their full name if it is in the
  # database, otherwise it is their e-mail address.
  def display_name
    last_name.blank? ?
      (first_name.blank? ? email : first_name) :
      (first_name.blank? ? last_name : (first_name + ' ' + last_name))
  end


  # -------------------------------------------------------------
  # Gets the username (without the domain) of the e-mail address, if possible.
  def email_without_domain
    if email =~ /(^[^@]+)@/
      $1
    else
      email
    end
  end


  # -------------------------------------------------------------
  def avatar_url(options = {})
    self.avatar.blank? ? gravatar_url(options) : self.avatar
  end


  # -------------------------------------------------------------
  def is_enrolled?(course_offering)
    course_offering && course_offerings.include?(course_offering)
  end


  # -------------------------------------------------------------
  def manages?(course_offering)
    role_for_course_offering(course_offering).andand.can_manage_course?
  end


  # -------------------------------------------------------------
  def teaches?(course_offering)
    role_for_course_offering(course_offering).andand.is_instructor?
  end


  # -------------------------------------------------------------
  def grades?(course_offering)
    role_for_course_offering(course_offering).andand.can_grade_submissions?
  end


  # -------------------------------------------------------------
  def is_staff?(course_offering)
    role_for_course_offering(course_offering).andand.is_staff?
  end


  # -------------------------------------------------------------
  def role_for_course_offering(course_offering)
    course_offering && course_enrollments.
      where(course_offering: course_offering).first.andand.course_role
  end


  # -------------------------------------------------------------
  # Omni auth for Facebook and Google Users
  def self.from_omniauth(auth, guest = nil)
    user = nil
    identity = Identity.where(uid: auth.uid, provider: auth.provider).first
    if identity
      user = identity.user
    else
      if auth.provider == :cas
        auth.info.email = auth.uid + '@vt.edu'
      end
      if auth.info.email
        user = User.where(email: auth.info.email).first
        if !user
          user = User.create(
            first_name: auth.info.first_name,
            last_name: auth.info.last_name,
            email: auth.info.email,
            confirmed_at: DateTime.now,
            password: Devise.friendly_token[0, 20])
        end
      end
      if user
        user.identities.create(uid: auth.uid, provider: auth.provider)
      end
    end

    # Update any blank fields from provider's info, if available
    if user
      user.first_name ||= auth.info.first_name
      user.last_name ||= auth.info.last_name
      user.email ||= auth.info.email
      user.avatar ||= auth.info.image
      user.remember_created_at = DateTime.now
      if !user.confirmed_at
        user.confirmed_at = user.remember_created_at
      end
      if user.changed?
        user.save
      end
    end
    return user
  end


  # -------------------------------------------------------------
  def normalize_friendly_id(value)
    value.split('@').map{ |x| CGI.escape x }.join('@')
  end


  #~ Private instance methods .................................................
  private

    # -------------------------------------------------------------
    # Sets the first user's role as administrator and subsequent users
    # as student (note: be sure to run rake db:seed to create these roles)
    def set_default_global_role
      if User.count == 0
        self.global_role = GlobalRole.administrator
      elsif self.global_role.nil?
        self.global_role = GlobalRole.regular_user
      end
    end


    # -------------------------------------------------------------
    # Overrides the built-in password required method to allow for users
    # to be updated without errors
    # taken from: http://www.chicagoinformatics.com/index.php/2012/09/
    # user-administration-for-devise/
    def password_required?
      (!password.blank? && !password_confirmation.blank?) || new_record?
    end


    # -------------------------------------------------------------
    def replace_dot(email)
      # HACK: because rails doesn't like periods in urls.
      email.gsub(/\./, '-dot-')
    end

    def email_or_id
      replace_dot(email) || id
    end


    # -------------------------------------------------------------
    def should_generate_new_friendly_id?
      slug.blank? || email_changed?
    end
end
