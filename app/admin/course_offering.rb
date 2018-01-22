ActiveAdmin.register CourseOffering, sort_order: :created_at_asc do
  includes :course, :term, :lms_instance

  remove_filter :users, :late_policy, :course_enrollments, :inst_books, :self_enrollment_allowed, :cutoff_date, :lms_course_code
  # filter :course_organization_name, :as => :string

  before_build do |record|
    record.user = current_user
  end

  menu parent: 'University-oriented', priority: 40
  permit_params :course_id, :term_id, :label, :url,
                :archived, :self_enrollment_allowed,
                :lms_instance_id, :lms_course_code, :lms_course_num,
                inst_books_attributes: [ :id, :course_offering_id, :user_id, :title, :desc, :template, :_destroy ]

  action_item only: [:edit] do |course_offering|
    if current_user.global_role.is_admin?
      message = course_offering_delete_msg(course_offering, 2)
      link_to "Delete", { action: :destroy }, method: :delete, data: {confirm: message}
    end
  end

  controller do

    before_filter archived: :index do
      params[:q] = {archived_eq: 0} if params[:commit].blank?
    end

    def scoped_collection
      CourseOffering.unscoped
    end
    def auto_enroll_instructor(course_offering)
      enrollment = CourseEnrollment.new
      enrollment.course_offering_id = course_offering.id
      enrollment.user_id = current_user.id
      enrollment.course_role_id = CourseRole.instructor.id
      enrollment.save
    end
  end

  after_create :auto_enroll_instructor

  index do
    id_column
    column :course, sortable: 'courses.display_name' do |c|
      link_to c.course.number_and_org, admin_course_path(c.course)
    end
    column :term, sortable: 'term.ends_on' do |c|
      link_to c.term.display_name, admin_term_path(c.term)
    end
    column :label do |c|
      link_to c.label, admin_course_offering_path(c)
    end
    column 'Archived?', :archived
    # column 'Self-enroll?', :self_enrollment_allowed
    # column(:url) { |c| link_to c.url, c.url }
    column :created_at
    # column :late_policy, sortable: 'late_policy.name'
    column :lms_instance, sortable: 'lms_instance.url'
    if current_user.global_role.is_admin?
      column :students_count, sortable: 'students count'
    end

    column "Actions" do |course_offering|
      message = course_offering_delete_msg(course_offering)
      links = ''.html_safe
      if authorized? :read, course_offering
        links += link_to "View", admin_course_offering_path(course_offering)
        links += ' '
      end
      if authorized? :update, course_offering
        links += link_to "Edit", admin_course_offering_path(course_offering)
        links += ' '
      end
      if authorized? :destroy, course_offering
        links += link_to "Delete", admin_course_offering_path(course_offering), method: :delete, data: {confirm: message}
        links += ' '
      end

      links
    end
  end

  form do |f|
    f.semantic_errors
    # f.inputs 'LMS Details:' do
    #   f.input :lms_instance
    #   f.input :lms_course_code
    #   f.input :lms_course_num
    # end
    f.inputs 'Course Offering Details:' do
      f.input :course, collection: Course.all.order(:slug, :name)
      f.input :term, collection: Term.order(:starts_on)
      f.input :label
      f.input :archived
      # f.input :late_policy
      # f.input :self_enrollment_allowed
    end
    # f.inputs 'OpenDSA Books:' do
    #   f.has_many :inst_books, heading: false, allow_destroy: true do |a|
    #     a.input :id
    #     a.input :user_id, :input_html => { :value => current_user.id }, as: :hidden
    #     # a.input :course_offering_id
    #     a.input :title
    #     a.input :desc ,label: 'Book Description'
    #     # a.input :template
    #   end
    # end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :course
      row :term
      row :label
      row :archived
      row :self_enrollment_allowed
      row :created_at
      row :updated_at
      row :lms_instance
      row :lms_course_code
      row :lms_course_num
    end

    panel 'OpenDSA Books' do
      table_for course_offering.inst_books do
        column :id
        column :title
        column "Book Description", :desc
      end
    end

    panel 'Roster' do
      table_for course_offering.students do
        column :name, :display_name
        column :email
      end
    end

  end

  sidebar 'Instructors', only: :show,
    if: proc{ course_offering.instructors.any? } do
    table_for course_offering.instructors do
      column(:name) { |i| link_to i.display_name, admin_user_path(i) }
      column(:email) { |i| link_to i.email, 'mailto:' + i.email }
    end
  end

  # sidebar 'Graders', only: :show,
  #   if: proc{ course_offering.graders.any? } do
  #   table_for course_offering.graders do
  #     column(:name) { |i| link_to i.display_name, admin_user_path(i) }
  #     column(:email) { |i| link_to i.email, 'mailto:' + i.email }
  #   end
  # end

end
