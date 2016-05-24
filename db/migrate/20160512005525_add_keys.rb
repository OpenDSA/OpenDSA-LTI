class AddKeys < ActiveRecord::Migration
  def change
    add_foreign_key "users", "time_zones", name: "users_time_zone_id_fk"
  end
end

