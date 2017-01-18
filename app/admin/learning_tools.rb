ActiveAdmin.register LearningTool, sort_order: :created_at_asc do
  menu label: "Learning Tools",parent: 'LMS config', priority: 5
  permit_params :name, :key, :secret, :launch_url
  actions :all

  index do
    id_column
    column :name
    column :key
    column :secret
    column :launch_url
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :key
      f.input :secret
      f.input :launch_url
    end
    f.actions
  end
end