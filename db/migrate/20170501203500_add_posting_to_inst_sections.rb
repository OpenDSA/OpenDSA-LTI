class AddPostingToInstSections < ActiveRecord::Migration
  def change
    add_column :inst_sections, :lms_posted, :boolean
    add_column :inst_sections, :time_posted, :datetime
  end
end
