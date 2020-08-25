class AddPostingToInstSections < ActiveRecord::Migration[5.1]
  def change
    add_column :inst_sections, :lms_posted, :boolean
    add_column :inst_sections, :time_posted, :datetime
  end
end
