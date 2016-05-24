ActiveAdmin.register InstBookOwner do
  includes :book_role, :inst_book, :user
  active_admin_import

  menu parent: 'ODSA Books', priority: 30
  permit_params :book_role_id, :inst_book_id, :user_id

  index do
    id_column
    column :book_role
    column :inst_book
    column :user
    column :created_at
    actions
  end

end
