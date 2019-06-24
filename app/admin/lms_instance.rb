ActiveAdmin.register LmsInstance do
  includes :lms_type, :organization

  menu label: "LMS Instances",parent: 'LMS config', priority: 20
  permit_params :url, :lms_type_id, :organization_id

  index do
    id_column
    column(:url) { |lms_inst| link_to lms_inst.url, admin_lms_instance_path(lms_inst) }
    column :lms_type
    column :organization
    # column :consumer_key
    # column :consumer_secret
    column :created_at
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :lms_type, collection: LmsType.all.order(:name)
      f.input :url
      f.input :organization, collection: Organization.all.order(:name)
      f.input :consumer_key
      f.input :consumer_secret
    end
    f.actions
  end

end