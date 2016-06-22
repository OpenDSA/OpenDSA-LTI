ActiveAdmin.register CourseEnrollment do
  includes :course_offering, :course_role, :user
  active_admin_import

  menu parent: 'University-oriented', priority: 45
  permit_params :course_offering_id, :course_role_id, :user_id

  index do
    id_column
    column :user, sortable: 'users.last_name' do |c|
      link_to c.user.display_name, admin_user_path(c.user)
    end
    column :course_offering, sortable: 'course_offerings.id' do |c|
      link_to c.course_offering.admin_display_name, admin_course_offering_path(c.course_offering)
    end
    column :course_role, sortable: 'course_roles.name' do |c|
      link_to c.course_role.name, admin_course_role_path(c.course_role)
    end
    actions
  end

end
