ActiveAdmin.register LmsType do
  active_admin_import

  menu parent: 'LMS config', priority: 10
  permit_params :name
  actions :all, except: [:destroy]

  index do
    id_column
    column(:name) { |lms| link_to lms.name, admin_lms_type_path(lms) }
    column :created_at
    actions
  end

  # sidebar 'Courses', only: :show do
  #   table_for organization.courses do
  #     column :number
  #     column(:name) { |c| link_to c.name, admin_course_path(c) }
  #   end
  # end

end

