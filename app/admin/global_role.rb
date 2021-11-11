# == Schema Information
#
# Table name: global_roles
#
#  id                            :bigint           not null, primary key
#  name                          :string(255)      not null
#  can_manage_all_courses        :boolean          default(FALSE), not null
#  can_edit_system_configuration :boolean          default(FALSE), not null
#  builtin                       :boolean          default(FALSE), not null
#
ActiveAdmin.register GlobalRole do
  actions :all, except: [:new, :create, :edit, :update, :destroy]

  menu parent: 'University-oriented', priority: 60

end
