ActiveAdmin.register Organization, sort_order: :created_at_asc do

  remove_filter :slugs, :courses, :abbreviation, :slug

  menu parent: 'University-oriented', priority: 20
  permit_params :name, :abbreviation

  index do
    id_column
    column(:name) { |org| link_to org.name, admin_organization_path(org) }
    column :abbreviation
    column :created_at
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :abbreviation
    end
    f.actions
  end

  sidebar 'Courses', only: :show do
    table_for organization.courses do
      column :number
      column(:name) { |c| link_to c.name, admin_course_path(c) }
    end
  end

end
