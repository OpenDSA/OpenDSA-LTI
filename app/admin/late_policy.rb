ActiveAdmin.register LatePolicy do
  active_admin_import

  menu parent: 'University-oriented', priority: 70
  permit_params :name, :late_days, :late_percent
  actions :all, except: [:destroy]

  index do
    id_column
    column(:name) { |c| link_to c.name, admin_late_policy_path(c) }
    column :late_days
    column :late_percent
    column :created_at
    actions
  end

end
