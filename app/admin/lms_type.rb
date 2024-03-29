# == Schema Information
#
# Table name: lms_types
#
#  id         :bigint           not null, primary key
#  name       :string(255)      not null
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_lms_types_on_name  (name) UNIQUE
#
ActiveAdmin.register LmsType do

  menu label: "LMS Types",parent: 'LMS config', priority: 10
  permit_params :name
  actions :all, except: [:destroy]

  index do
    id_column
    column(:name) { |lms| link_to lms.name, admin_lms_type_path(lms) }
    column :created_at
    actions
  end

  # sidebar 'Courses', only: :show do
  #   table_for organization.courses do
  #     column :number
  #     column(:name) { |c| link_to c.name, admin_course_path(c) }
  #   end
  # end

end

