class AddForeignKeyConstraints < ActiveRecord::Migration
  def change
    add_foreign_key :course_enrollments, :course_offerings, dependent: :delete
    add_foreign_key :course_enrollments, :course_roles
    add_foreign_key :course_enrollments, :users, dependent: :delete
    add_foreign_key :course_offerings, :courses, dependent: :delete
    add_foreign_key :course_offerings, :terms, dependent: :delete
    add_foreign_key :courses, :organizations, dependent: :delete
    add_foreign_key :identities, :users, dependent: :delete
    add_foreign_key :users, :global_roles
  end
end
