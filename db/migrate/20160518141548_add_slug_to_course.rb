class AddSlugToCourse < ActiveRecord::Migration
  # def change
  #   add_column :courses, :slug, :string
  #   add_index :courses, :slug, unique: true
  # end

  def up
    add_column :courses, :slug, :string
    # Force generation of slug values for all entries
    Course.reset_column_information
    Course.all.map(&:save)
    change_column_null :courses, :slug, false
    add_index :courses, :slug
  end

  def down
    # No way to regenerate the url_part content, since the code was
    # removed from the model!
    raise ActiveRecord::IrreversibleMigration
  end


end
