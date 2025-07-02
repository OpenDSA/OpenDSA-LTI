class CreateTimeZones < ActiveRecord::Migration[5.1]
  def change
    create_table :time_zones do |t|
      t.string :name
      t.string :zone
      t.string :display_as
      t.string :name_formatted

      t.timestamps
    end
  end
end
