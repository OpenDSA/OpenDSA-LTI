ActiveAdmin.register InstBookOwner do
  includes :inst_book, :user
  active_admin_import

  menu parent: 'ODSA Books', priority: 30
  permit_params :inst_book_id, :user_id

  index do
    id_column
    column :inst_book
    column :user
    column :created_at
    actions
  end

end
