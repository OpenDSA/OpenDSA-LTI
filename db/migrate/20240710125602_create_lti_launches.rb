class CreateLtiLaunches < ActiveRecord::Migration[6.0]
  def change
    # Drop the table if it exists 
    drop_table :lti_launches, if_exists: true

    create_table :lti_launches do |t|
      t.integer :lms_instance_id, null: false
      t.integer :user_id, null: false
      t.text :id_token, limit: 65535 
      t.json :decoded_jwt
      t.string :kid
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_foreign_key :lti_launches, :lms_instances
    add_foreign_key :lti_launches, :users
    add_index :lti_launches, :expires_at
  end
end


