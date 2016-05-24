ActiveAdmin.register InstBook do
  includes :course_offering
  active_admin_import

  menu parent: 'ODSA Books', priority: 20
  permit_params :title, :book_url, :book_code, :course_offering_id

  index do
    id_column
    column :title
    column :book_url
    column :book_code
    column :course_offering
    column :created_at
    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :course_offering
      f.input :title
      f.input :book_url
      f.input :book_code
    end
    f.actions
  end

end
