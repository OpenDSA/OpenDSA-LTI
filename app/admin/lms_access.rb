# == Schema Information
#
# Table name: lms_accesses
#
#  id              :bigint           not null, primary key
#  access_token    :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  lms_instance_id :bigint           not null
#  user_id         :bigint           not null
#  consumer_key    :string(255)
#  consumer_secret :string(255)
#
# Indexes
#
#  index_lms_accesses_on_lms_instance_id_and_user_id  (lms_instance_id,user_id) UNIQUE
#  lms_accesses_user_id_fk                            (user_id)
#
ActiveAdmin.register LmsAccess, sort_order: :created_at_asc do
  includes :lms_instance, :user

  before_build do |record|
    record.user = current_user
  end

  menu label: "LMS Accesses", parent: 'LMS config', priority: 30
  permit_params :lms_instance_id, :user_id, :access_token, :consumer_key

  filter :user_email_cont, as: String, label: "Email"

  index do
    id_column

    column :lms_instance, sortable: 'lms_instances.url' do |c|
      if c.lms_instance
        link_to c.lms_instance.url, admin_lms_instance_path(c.lms_instance)
      end
    end

    column :first_name, sortable: 'users.first_name' do |c|
      link_to c.user.first_name, admin_user_path(c.user)
    end
    column :last_name, sortable: 'users.last_name' do |c|
      link_to c.user.last_name, admin_user_path(c.user)
    end
    column :email, sortable: 'users.email' do |c|
      link_to c.user.email, admin_user_path(c.user)
    end
    column :access_token do |c|
      link_to c.access_token, admin_lms_access_path(c)
    end
    # column :created_at
    column :consumer_key
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
      f.input :consumer_key
    end
    f.actions
  end
end
