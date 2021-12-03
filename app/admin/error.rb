# == Schema Information
#
# Table name: errors
#
#  id          :bigint           not null, primary key
#  usable_type :string(255)
#  usable_id   :bigint
#  class_name  :string(255)
#  message     :text(65535)
#  trace       :text(65535)
#  target_url  :text(65535)
#  referer_url :text(65535)
#  params      :text(65535)
#  user_agent  :text(65535)
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_errors_on_class_name  (class_name)
#  index_errors_on_created_at  (created_at)
#
ActiveAdmin.register Error,
  sort_order: :created_at_desc do
  actions :all, except: [:new, :create, :update, :edit, :destroy]

  menu priority: 1000

  index do
    column :class_name
    column(:message) { |e| link_to e.message, admin_error_path(e) }
    column 'URL', :target_url
    column :time, :created_at
    actions
  end

end
