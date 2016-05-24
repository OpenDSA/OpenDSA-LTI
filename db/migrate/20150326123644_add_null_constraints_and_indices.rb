class AddNullConstraintsAndIndices < ActiveRecord::Migration
  def change
    # identities
    change_column_null :identities, :user_id, false
    change_column_null :identities, :provider, false
    change_column_null :identities, :uid, false
    add_index :identities, [:uid, :provider]

    # organizations
    change_column_null :organizations, :display_name, false
    change_column_null :organizations, :url_part, false

    # courses
    change_column_null :courses, :name, false
    change_column_null :courses, :number, false
    change_column_null :courses, :organization_id, false
    change_column_null :courses, :url_part, false

    # course_offerings
    change_column_null :course_offerings, :name, false
    change_column_null :course_offerings, :course_id, false
    change_column_null :course_offerings, :term_id, false

    # terms
    change_column_null :terms, :season, false
    change_column_null :terms, :year, false
    change_column_null :terms, :starts_on, false
    change_column_null :terms, :ends_on, false
    add_index :terms, [:year, :season]

    # course_enrollments
    change_column_null :course_enrollments, :user_id, false
    change_column_null :course_enrollments, :course_offering_id, false
    change_column_null :course_enrollments, :course_role_id, false

    # users
    change_column_null :users, :global_role_id, false
  end
end
