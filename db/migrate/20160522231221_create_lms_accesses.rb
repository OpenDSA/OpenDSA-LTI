class CreateLmsAccesses < ActiveRecord::Migration[5.1]
  def change
    create_table :lms_accesses do |t|
      t.string :access_token, null: false

      t.timestamps
    end
  end
end
