ActiveAdmin.register LmsAccess do
  scope_to :current_user, unless: proc{ current_user.global_role.is_admin? }
  includes :lms_instance, :user
  active_admin_import

  menu parent: 'LMS config', priority: 30
  permit_params :lms_instance_id, :user_id, :access_token

  index do
    id_column
    column :lms_instance, sortable: 'lms_instances.url' do |c|
      link_to c.lms_instance.url, admin_lms_instance_path(c.lms_instance)
    end
    column :user, sortable: 'user.display_name' do |c|
      link_to c.user.display_name, admin_user_path(c.user)
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
        f.input :user
      end
      f.input :access_token
    end
    f.actions
  end
end
