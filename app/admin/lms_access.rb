ActiveAdmin.register LmsAccess, sort_order: :created_at_asc do
  includes :lms_instance, :user

  before_build do |record|
    record.user = current_user
  end

  menu label: "LMS Accesses", parent: 'LMS config', priority: 30
  permit_params :lms_instance_id, :user_id, :access_token

  index do
    id_column

    column :lms_instance, sortable: 'lms_instances.url' do |c|
      if c.lms_instance
        link_to c.lms_instance.url, admin_lms_instance_path(c.lms_instance)
      end
    end

    column :user, sortable: 'user.display_name' do |c|
      link_to c.user.display_name, admin_user_path(c.user)
    end
    column :user, sortable: 'user.email' do |c|
      link_to c.user.email, admin_user_path(c.user)
    end
    column :access_token do |c|
      link_to c.access_token, admin_lms_access_path(c)
    end
    # column :created_at
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :lms_instance
      if current_user.global_role.is_admin?
        f.input :user, collection: User.all.order(:first_name, :last_name)
      end
      f.input :access_token
    end
    f.actions
  end
end
