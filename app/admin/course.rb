ActiveAdmin.register Course, sort_order: :created_at_asc do
  includes :organization, :user

  remove_filter :slugs, :user, :course_offerings

  before_build do |record|
    record.user = current_user
  end

  menu parent: 'University-oriented', priority: 30
  permit_params :name, :number, :organization_id, :user_id

  index do
    id_column
    column :number
    column (:name) { |c| link_to c.name, admin_course_path(c) }
    column :organization, sortable: 'organizations.name'
    if current_user.global_role.is_admin?
      column "Owner", :user
    end
    column :created_at
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :organization, collection: Organization.all.order(:name)
      if current_user.global_role.is_admin?
        f.input :user, collection: User.all.order(:first_name, :last_name)
      end
      f.input :number
      f.input :name
    end
    f.actions
  end

  # sidebar 'Offerings', only: :show do
  #   table_for course.course_offerings do
  #     column(:term) { |c| c.term.display_name }
  #     column(:name) do |c|
  #       link_to c.display_name, admin_course_offering_path(c)
  #     end
  #   end
  # end

end
