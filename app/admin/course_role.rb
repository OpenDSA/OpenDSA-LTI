# == Schema Information
#
# Table name: course_roles
#
#  id                         :bigint           not null, primary key
#  name                       :string(255)      not null
#  can_manage_course          :boolean          default(FALSE), not null
#  can_manage_assignments     :boolean          default(FALSE), not null
#  can_grade_submissions      :boolean          default(FALSE), not null
#  can_view_other_submissions :boolean          default(FALSE), not null
#  builtin                    :boolean          default(FALSE), not null
#
ActiveAdmin.register CourseRole do
  actions :all, except: [:destroy]

  menu parent: 'University-oriented', priority: 50

end
