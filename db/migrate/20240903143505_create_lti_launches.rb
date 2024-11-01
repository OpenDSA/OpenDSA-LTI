class CreateLtiLaunches < ActiveRecord::Migration[6.0]
  def change
    create_table :lti_launches do |t|
      t.integer :lms_instance_id, null: false
      t.integer :user_id, null: false
      t.integer :course_offering_id, null: false
      t.text :id_token, limit: 65535 
      t.json :decoded_jwt
      t.string :kid
      t.datetime :expires_at, null: false

      t.timestamps
    end

    # Add foreign keys
    add_foreign_key :lti_launches, :lms_instances
    add_foreign_key :lti_launches, :users
    add_foreign_key :lti_launches, :course_offerings #course_offering_id

    add_index :lti_launches, :expires_at
    add_index :lti_launches, :course_offering_id
  end
end
