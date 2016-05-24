ActiveAdmin.register BookRole do
  active_admin_import

  menu parent: 'ODSA Books', priority: 10
  permit_params :name, :can_modify, :can_compile
  actions :all, except: [:destroy]

  index do
    id_column
    column :name
    column :can_modify
    column :can_compile
    actions
  end
end
