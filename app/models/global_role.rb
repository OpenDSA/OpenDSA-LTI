class GlobalRole < ActiveRecord::Base
  self.table_name = 'global_roles'
  self.inheritance_column = 'ruby_type'
  self.primary_key = 'id'

  if ActiveRecord::VERSION::STRING < '4.0.0' || defined?(ProtectedAttributes)
    attr_accessible :name, :can_manage_all_courses, :can_edit_system_configuration, :builtin, :created_at, :updated_at
  end

  has_many :users, :foreign_key => 'global_role_id', :class_name => 'User'
  has_many :time_zones, :through => :users, :foreign_key => 'time_zone_id', :class_name => 'TimeZone'

  #~ Validation ...............................................................

  validates :name, presence: true, uniqueness: true

  with_options if: :builtin?, on: :update, changeable: false do |builtin|
    builtin.validates :can_edit_system_configuration
    builtin.validates :can_manage_all_courses
  end

  before_destroy :check_builtin?


  #~ Constants ................................................................

  # Make sure to run rake db:seed after initial database creation
  # to ensure that the built-in roles with these IDs are created.
  # These IDs should not be referred to directly in most cases;
  # use the class methods below to fetch the actual role object
  # instead.
  ADMINISTRATOR_ID = 1
  INSTRUCTOR_ID    = 2
  REGULAR_USER_ID  = 3


  #~ Class methods ............................................................

  # -------------------------------------------------------------
  def self.administrator
    find(ADMINISTRATOR_ID)
  end


  # -------------------------------------------------------------
  def self.instructor
    find(INSTRUCTOR_ID)
  end


  # -------------------------------------------------------------
  def self.regular_user
    find(REGULAR_USER_ID)
  end


  #~ Instance methods .........................................................

  # -------------------------------------------------------------
  def check_builtin?
    errors.add :base, "Cannot delete built-in roles." if builtin?
    errors.blank?
  end


  # -------------------------------------------------------------
  def is_instructor?
    id == INSTRUCTOR_ID
  end


  # -------------------------------------------------------------
  def is_admin?
    id == ADMINISTRATOR_ID
  end


  # -------------------------------------------------------------
  def is_regular_user?
    id == REGULAR_USER_ID
  end

end
