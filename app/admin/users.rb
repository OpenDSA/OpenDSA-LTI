ActiveAdmin.register User do
  menu if: proc{ current_user.global_role.is_admin? }

  remove_filter :odsa_exercise_attempts, :odsa_exercise_progresses,
                :odsa_module_progresses, :odsa_book_progresses, :odsa_user_interactions,
                :course_enrollments, :identities, :lms_accesses, :inst_books, :encrypted_password,
                :reset_password_token, :reset_password_sent_at, :remember_created_at,
                :current_sign_in_ip ,:last_sign_in_ip ,:confirmation_token ,:confirmed_at ,
                :confirmation_sent_at

  includes :global_role
  actions :all, except: [:new]
  permit_params :first_name, :last_name, :email,
    :confirmed_at, :global_role_id, :avatar

  index do
    selectable_column
    id_column
    column :last_name
    column :first_name
    column(:email) { |u| link_to u.email, 'mailto:' + u.email }
    column :confirmed, :confirmed_at
    column :last_login, :last_sign_in_at
    column 'Last IP', :last_sign_in_ip
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      if current_user.global_role.is_admin?
        f.input :global_role
      end
      f.input :last_name
      f.input :first_name
      f.input :email
    end
    f.actions
  end

  # sidebar 'Teaching Courses', only: :show,
  #   if: proc{ user.instructor_course_offerings.any? } do
  #   table_for user.instructor_course_offerings do
  #     column(:term) {|c| link_to c.term.display_name, admin_term_path(c.term)}
  #     column :offering do |c|
  #       link_to c.display_name, admin_course_offering_path(c)
  #     end
  #   end
  # end

  # sidebar 'Grading Courses', only: :show,
  #   if: proc{ user.grader_course_offerings.any? } do
  #   table_for user.grader_course_offerings do
  #     column(:term) {|c| link_to c.term.display_name, admin_term_path(c.term)}
  #     column :offering do |c|
  #       link_to c.display_name, admin_course_offering_path(c)
  #     end
  #   end
  # end

end
