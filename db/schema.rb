# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_11_16_040517) do

  create_table "active_admin_comments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_id", null: false
    t.string "resource_type", null: false
    t.integer "author_id"
    t.string "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "course_enrollments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "course_offering_id", null: false
    t.integer "course_role_id", null: false
    t.index ["course_offering_id"], name: "index_course_enrollments_on_course_offering_id"
    t.index ["course_role_id"], name: "index_course_enrollments_on_course_role_id"
    t.index ["user_id", "course_offering_id"], name: "index_course_enrollments_on_user_id_and_course_offering_id", unique: true
    t.index ["user_id"], name: "index_course_enrollments_on_user_id"
  end

  create_table "course_offerings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "course_id", null: false
    t.integer "term_id", null: false
    t.string "label", null: false
    t.string "url"
    t.boolean "self_enrollment_allowed", default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date "cutoff_date"
    t.integer "late_policy_id"
    t.integer "lms_instance_id", null: false
    t.string "lms_course_code"
    t.string "lms_course_num", null: false
    t.boolean "archived", default: false
    t.index ["course_id"], name: "index_course_offerings_on_course_id"
    t.index ["late_policy_id"], name: "course_offerings_late_policy_id_fk"
    t.index ["lms_instance_id", "lms_course_num"], name: "index_course_offerings_on_lms_instance_id_and_lms_course_num"
    t.index ["term_id"], name: "index_course_offerings_on_term_id"
  end

  create_table "course_roles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "can_manage_course", default: false, null: false
    t.boolean "can_manage_assignments", default: false, null: false
    t.boolean "can_grade_submissions", default: false, null: false
    t.boolean "can_view_other_submissions", default: false, null: false
    t.boolean "builtin", default: false, null: false
  end

  create_table "courses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "number", null: false
    t.integer "organization_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug", null: false
    t.index ["organization_id"], name: "index_courses_on_organization_id"
    t.index ["slug"], name: "index_courses_on_slug"
    t.index ["user_id"], name: "index_courses_on_user_id"
  end

  create_table "delayed_jobs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "progress_stage"
    t.integer "progress_current", default: 0
    t.integer "progress_max", default: 0
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "errors", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "usable_type"
    t.integer "usable_id"
    t.string "class_name"
    t.text "message"
    t.text "trace"
    t.text "target_url"
    t.text "referer_url"
    t.text "params"
    t.text "user_agent"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["class_name"], name: "index_errors_on_class_name"
    t.index ["created_at"], name: "index_errors_on_created_at"
  end

  create_table "friendly_id_slugs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "global_roles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "can_manage_all_courses", default: false, null: false
    t.boolean "can_edit_system_configuration", default: false, null: false
    t.boolean "builtin", default: false, null: false
  end

  create_table "identities", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["uid", "provider"], name: "index_identities_on_uid_and_provider"
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "inst_book_section_exercises", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "inst_book_id", null: false
    t.integer "inst_section_id", null: false
    t.integer "inst_exercise_id"
    t.decimal "points", precision: 5, scale: 2, null: false
    t.boolean "required", default: false
    t.decimal "threshold", precision: 5, scale: 2, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "type"
    t.text "options", size: :long
    t.boolean "partial_credit", default: false
    t.text "json"
    t.index ["inst_book_id"], name: "inst_book_section_exercises_inst_book_id_fk"
    t.index ["inst_exercise_id"], name: "inst_book_section_exercises_inst_exercise_id_fk"
    t.index ["inst_section_id"], name: "inst_book_section_exercises_inst_section_id_fk"
  end

  create_table "inst_books", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "course_offering_id"
    t.integer "user_id", null: false
    t.string "title", limit: 50, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "template", default: false
    t.string "desc"
    t.datetime "last_compiled"
    t.text "options", size: :long
    t.integer "book_type"
    t.index ["course_offering_id"], name: "inst_books_course_offering_id_fk"
    t.index ["user_id"], name: "inst_books_user_id_fk"
  end

  create_table "inst_chapter_modules", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "inst_chapter_id", null: false
    t.integer "inst_module_id", null: false
    t.integer "module_position"
    t.integer "lms_module_item_id"
    t.integer "lms_section_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "lms_assignment_id"
    t.datetime "due_dates"
    t.index ["inst_chapter_id"], name: "inst_chapter_modules_inst_chapter_id_fk"
    t.index ["inst_module_id"], name: "inst_chapter_modules_inst_module_id_fk"
  end

  create_table "inst_chapters", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "inst_book_id", null: false
    t.string "name", limit: 100, null: false
    t.string "short_display_name", limit: 45
    t.integer "position"
    t.integer "lms_chapter_id"
    t.integer "lms_assignment_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["inst_book_id"], name: "inst_chapters_inst_book_id_fk"
  end

  create_table "inst_course_offering_exercises", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "course_offering_id", null: false
    t.integer "inst_exercise_id", null: false
    t.string "resource_link_id"
    t.string "resource_link_title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal "threshold", precision: 5, scale: 2, null: false
    t.decimal "points", precision: 5, scale: 2, null: false
    t.text "options", size: :long
    t.index ["course_offering_id", "resource_link_id", "inst_exercise_id"], name: "index_inst_course_offering_exercises_on_course_offering_res", unique: true
    t.index ["inst_exercise_id"], name: "inst_course_offering_exercises_inst_exercise_id_fk"
  end

  create_table "inst_exercises", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "short_name", null: false
    t.string "ex_type", limit: 50
    t.string "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "learning_tool"
    t.string "av_address", limit: 512
    t.integer "width"
    t.integer "height"
    t.text "links"
    t.text "scripts"
    t.index ["short_name"], name: "index_inst_exercises_on_short_name", unique: true
  end

  create_table "inst_module_section_exercises", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "inst_module_version_id", null: false
    t.integer "inst_module_section_id", null: false
    t.integer "inst_exercise_id", null: false
    t.decimal "points", precision: 5, scale: 2, null: false
    t.boolean "required", default: false
    t.decimal "threshold", precision: 5, scale: 2, null: false
    t.text "options"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "partial_credit", default: false
    t.index ["inst_exercise_id"], name: "fk_rails_9b61737c9f"
    t.index ["inst_module_section_id"], name: "fk_rails_b320810099"
    t.index ["inst_module_version_id"], name: "fk_rails_5c4fc2ff52"
  end

  create_table "inst_module_sections", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "inst_module_version_id", null: false
    t.string "name", null: false
    t.boolean "show", default: true
    t.string "learning_tool"
    t.string "resource_type"
    t.string "resource_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inst_module_version_id"], name: "fk_rails_ff11275e48"
  end

  create_table "inst_module_versions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "inst_module_id", null: false
    t.string "name", null: false
    t.string "git_hash", null: false
    t.string "file_path", limit: 4096, null: false
    t.boolean "template", default: false
    t.integer "course_offering_id"
    t.string "resource_link_id"
    t.string "resource_link_title", limit: 512
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_offering_id", "resource_link_id"], name: "index_inst_module_versions_on_course_resource", unique: true
    t.index ["inst_module_id"], name: "fk_rails_7e343b3134"
  end

  create_table "inst_modules", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "path", null: false
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "current_version_id"
    t.index ["current_version_id"], name: "fk_rails_73d3622e40"
    t.index ["path"], name: "index_inst_modules_on_path", unique: true
  end

  create_table "inst_sections", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "inst_module_id", null: false
    t.integer "inst_chapter_module_id", null: false
    t.string "short_display_name", limit: 50
    t.string "name", null: false
    t.integer "position"
    t.boolean "gradable", default: false
    t.datetime "soft_deadline"
    t.datetime "hard_deadline"
    t.integer "time_limit"
    t.boolean "show", default: true
    t.integer "lms_item_id"
    t.integer "lms_assignment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "learning_tool"
    t.string "resource_type"
    t.string "resource_name"
    t.boolean "lms_posted"
    t.datetime "time_posted"
    t.index ["inst_chapter_module_id"], name: "inst_sections_inst_chapter_module_id_fk"
    t.index ["inst_module_id"], name: "inst_sections_inst_module_id_fk"
  end

  create_table "languages", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "late_policies", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "late_days", null: false
    t.integer "late_percent", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_late_policies_on_name", unique: true
  end

  create_table "learning_tools", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "key", null: false
    t.string "secret", null: false
    t.string "launch_url", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_learning_tools_on_name", unique: true
  end

  create_table "lms_accesses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "access_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "lms_instance_id", null: false
    t.integer "user_id", null: false
    t.string "consumer_key"
    t.string "consumer_secret"
    t.index ["lms_instance_id", "user_id"], name: "index_lms_accesses_on_lms_instance_id_and_user_id", unique: true
    t.index ["user_id"], name: "lms_accesses_user_id_fk"
  end

  create_table "lms_instances", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "url", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "lms_type_id"
    t.string "consumer_key"
    t.string "consumer_secret"
    t.integer "organization_id"
    t.index ["lms_type_id"], name: "lms_instances_lms_type_id_fk"
    t.index ["organization_id"], name: "lms_instances_organization_id_fk"
    t.index ["url"], name: "index_lms_instances_on_url", unique: true
  end

  create_table "lms_types", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_lms_types_on_name", unique: true
  end

  create_table "odsa_book_progresses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "inst_book_id", null: false
    t.text "started_exercises", size: :long, null: false
    t.text "proficient_exercises", size: :long, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["inst_book_id"], name: "odsa_book_progresses_inst_book_id_fk"
    t.index ["user_id", "inst_book_id"], name: "index_odsa_book_progresses_on_user_id_and_inst_book_id", unique: true
  end

  create_table "odsa_bugs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "os_family", limit: 50, null: false
    t.string "browser_family", limit: 20, null: false
    t.string "title", limit: 50, null: false
    t.text "description", size: :long, null: false
    t.string "screenshot", limit: 100
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "odsa_exercise_attempts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "inst_book_id"
    t.integer "inst_section_id"
    t.integer "inst_book_section_exercise_id"
    t.boolean "worth_credit", null: false
    t.datetime "time_done", null: false
    t.integer "time_taken", null: false
    t.integer "count_hints", null: false
    t.boolean "hint_used", null: false
    t.decimal "points_earned", precision: 5, scale: 2, null: false
    t.boolean "earned_proficiency", null: false
    t.bigint "count_attempts", null: false
    t.string "ip_address", limit: 20, null: false
    t.string "question_name", limit: 50, null: false
    t.string "request_type", limit: 50
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "correct"
    t.decimal "pe_score", precision: 5, scale: 2
    t.integer "pe_steps_fixed"
    t.integer "inst_course_offering_exercise_id"
    t.integer "inst_module_section_exercise_id"
    t.string "answer"
    t.integer "question_id"
    t.boolean "finished_frame"
    t.index ["inst_book_id"], name: "odsa_exercise_attempts_inst_book_id_fk"
    t.index ["inst_book_section_exercise_id"], name: "odsa_exercise_attempts_inst_book_section_exercise_id_fk"
    t.index ["inst_course_offering_exercise_id"], name: "odsa_exercise_attempts_inst_course_offering_exercise_id_fk"
    t.index ["inst_module_section_exercise_id"], name: "fk_rails_6944f2321b"
    t.index ["inst_section_id"], name: "odsa_exercise_attempts_inst_section_id_fk"
    t.index ["user_id"], name: "odsa_exercise_attempts_user_id_fk"
  end

  create_table "odsa_exercise_progresses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "inst_book_section_exercise_id"
    t.integer "current_score", null: false
    t.integer "highest_score", null: false
    t.datetime "first_done", null: false
    t.datetime "last_done", null: false
    t.integer "total_correct", null: false
    t.integer "total_worth_credit", null: false
    t.datetime "proficient_date", null: false
    t.string "current_exercise"
    t.string "correct_exercises"
    t.string "hinted_exercise"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "inst_course_offering_exercise_id"
    t.string "lis_outcome_service_url"
    t.string "lis_result_sourcedid"
    t.integer "lms_access_id"
    t.integer "inst_module_section_exercise_id"
    t.index ["inst_book_section_exercise_id"], name: "odsa_exercise_progresses_inst_book_section_exercise_id_fk"
    t.index ["inst_course_offering_exercise_id"], name: "odsa_exercise_progresses_inst_course_offering_exercise_id_fk"
    t.index ["inst_module_section_exercise_id"], name: "fk_rails_7b1bb7d31f"
    t.index ["lms_access_id"], name: "fk_rails_3327f6b532"
    t.index ["user_id", "inst_book_section_exercise_id"], name: "index_odsa_ex_prog_on_user_id_and_inst_bk_sec_ex_id", unique: true
    t.index ["user_id", "inst_course_offering_exercise_id"], name: "index_odsa_exercise_prog_on_user_course_offering_exercise", unique: true
    t.index ["user_id", "inst_module_section_exercise_id"], name: "index_odsa_ex_prog_on_user_module_sec_ex", unique: true
  end

  create_table "odsa_module_progresses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "inst_book_id"
    t.datetime "first_done", null: false
    t.datetime "last_done", null: false
    t.datetime "proficient_date", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "inst_chapter_module_id"
    t.string "lis_outcome_service_url"
    t.string "lis_result_sourcedid"
    t.float "current_score", null: false
    t.float "highest_score", null: false
    t.integer "lms_access_id"
    t.integer "inst_module_version_id"
    t.datetime "last_passback", null: false
    t.index ["inst_book_id"], name: "odsa_module_progresses_inst_book_id_fk"
    t.index ["inst_chapter_module_id"], name: "odsa_module_progresses_inst_chapter_module_id_fk"
    t.index ["inst_module_version_id"], name: "fk_rails_38a9ac7560"
    t.index ["lms_access_id"], name: "odsa_module_progresses_lms_access_id_fk"
    t.index ["user_id", "inst_chapter_module_id"], name: "index_odsa_module_progress_on_user_and_module", unique: true
    t.index ["user_id", "inst_module_version_id"], name: "index_odsa_mod_prog_on_user_mod_version", unique: true
  end

  create_table "odsa_student_extensions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "inst_section_id", null: false
    t.datetime "soft_deadline"
    t.datetime "hard_deadline"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "time_limit"
    t.datetime "opening_date"
    t.index ["inst_section_id"], name: "odsa_student_extensions_inst_section_id_fk"
    t.index ["user_id"], name: "odsa_student_extensions_user_id_fk"
  end

  create_table "odsa_user_interactions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "inst_book_id"
    t.integer "inst_section_id"
    t.integer "inst_book_section_exercise_id"
    t.string "name", limit: 50, null: false
    t.text "description", size: :long, null: false
    t.datetime "action_time", null: false
    t.bigint "uiid", null: false
    t.string "browser_family", limit: 20, null: false
    t.string "browser_version", limit: 20, null: false
    t.string "os_family", limit: 50, null: false
    t.string "os_version", limit: 20, null: false
    t.string "device", limit: 50, null: false
    t.string "ip_address", limit: 20, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "inst_course_offering_exercise_id"
    t.integer "inst_chapter_module_id"
    t.integer "inst_module_version_id"
    t.integer "inst_module_section_exercise_id"
    t.index ["inst_book_id"], name: "odsa_user_interactions_inst_book_id_fk"
    t.index ["inst_book_section_exercise_id"], name: "odsa_user_interactions_inst_book_section_exercise_id_fk"
    t.index ["inst_chapter_module_id"], name: "index_odsa_user_interactions_on_inst_chapter_module"
    t.index ["inst_course_offering_exercise_id"], name: "odsa_user_interactions_inst_course_offering_exercise_id_fk"
    t.index ["inst_module_section_exercise_id"], name: "fk_rails_9d3d089a83"
    t.index ["inst_module_version_id"], name: "fk_rails_599b647d17"
    t.index ["inst_section_id"], name: "odsa_user_interactions_inst_section_id_fk"
    t.index ["user_id"], name: "odsa_user_interactions_user_id_fk"
  end

  create_table "odsa_user_time_trackings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "inst_book_id"
    t.integer "inst_section_id"
    t.integer "inst_book_section_exercise_id"
    t.integer "inst_course_offering_exercise_id"
    t.integer "inst_module_id"
    t.integer "inst_chapter_id"
    t.integer "inst_module_version_id"
    t.integer "inst_module_section_exercise_id"
    t.string "uuid", limit: 50, null: false
    t.string "session_date", limit: 50, null: false
    t.decimal "total_time", precision: 10, scale: 2, null: false
    t.text "sections_time", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["inst_book_id", "session_date"], name: "index_odsa_user_time_trackings_on_inst_book_id_session_date"
    t.index ["inst_book_section_exercise_id"], name: "odsa_user_time_tracking_inst_book_section_exercise_id_fk"
    t.index ["inst_chapter_id"], name: "odsa_user_time_tracking_inst_chapter_id_fk"
    t.index ["inst_course_offering_exercise_id"], name: "odsa_user_time_tracking_inst_course_offering_exercise_id_fk"
    t.index ["inst_module_id"], name: "odsa_user_time_tracking_inst_module_id_fk"
    t.index ["inst_module_section_exercise_id"], name: "odsa_user_time_tracking_inst_module_section_exercise_id_fk"
    t.index ["inst_module_version_id"], name: "odsa_user_time_tracking_inst_module_version_id_fk"
    t.index ["inst_section_id"], name: "odsa_user_time_tracking_inst_section_id_fk"
    t.index ["user_id", "uuid"], name: "index_odsa_user_time_trackings_on_user_id_uuid", unique: true
  end

  create_table "organizations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "abbreviation"
    t.string "slug", null: false
    t.index ["name"], name: "index_organizations_on_name", unique: true
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "pi_attempts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "frame_name"
    t.integer "question"
    t.integer "correct"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "student_exercise_progresses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "exercise_id", null: false
    t.text "progress"
    t.decimal "grade", precision: 5, scale: 2, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "terms", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "season", null: false
    t.date "starts_on", null: false
    t.date "ends_on", null: false
    t.integer "year", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug", null: false
    t.index ["slug"], name: "index_terms_on_slug", unique: true
    t.index ["starts_on"], name: "index_terms_on_starts_on"
    t.index ["year", "season"], name: "index_terms_on_year_and_season"
  end

  create_table "time_zones", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "zone"
    t.string "display_as"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "first_name"
    t.string "last_name"
    t.integer "global_role_id", null: false
    t.string "avatar"
    t.string "slug", null: false
    t.integer "time_zone_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["global_role_id"], name: "index_users_on_global_role_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
    t.index ["time_zone_id"], name: "index_users_on_time_zone_id"
  end

  add_foreign_key "course_enrollments", "course_offerings", name: "course_enrollments_course_offering_id_fk", on_delete: :cascade
  add_foreign_key "course_enrollments", "course_roles", name: "course_enrollments_course_role_id_fk"
  add_foreign_key "course_enrollments", "users", name: "course_enrollments_user_id_fk", on_delete: :cascade
  add_foreign_key "course_offerings", "courses", name: "course_offerings_course_id_fk", on_delete: :cascade
  add_foreign_key "course_offerings", "late_policies", name: "course_offerings_late_policy_id_fk"
  add_foreign_key "course_offerings", "lms_instances", name: "course_offerings_lms_instance_id_fk"
  add_foreign_key "course_offerings", "terms", name: "course_offerings_term_id_fk", on_delete: :cascade
  add_foreign_key "courses", "organizations", name: "courses_organization_id_fk", on_delete: :cascade
  add_foreign_key "identities", "users", name: "identities_user_id_fk", on_delete: :cascade
  add_foreign_key "inst_book_section_exercises", "inst_books", name: "inst_book_section_exercises_inst_book_id_fk"
  add_foreign_key "inst_book_section_exercises", "inst_exercises", name: "inst_book_section_exercises_inst_exercise_id_fk"
  add_foreign_key "inst_book_section_exercises", "inst_sections", name: "inst_book_section_exercises_inst_section_id_fk"
  add_foreign_key "inst_books", "course_offerings", name: "inst_books_course_offering_id_fk"
  add_foreign_key "inst_books", "users", name: "inst_books_user_id_fk"
  add_foreign_key "inst_chapter_modules", "inst_chapters", name: "inst_chapter_modules_inst_chapter_id_fk"
  add_foreign_key "inst_chapter_modules", "inst_modules", name: "inst_chapter_modules_inst_module_id_fk"
  add_foreign_key "inst_chapters", "inst_books", name: "inst_chapters_inst_book_id_fk"
  add_foreign_key "inst_course_offering_exercises", "course_offerings"
  add_foreign_key "inst_course_offering_exercises", "inst_exercises", name: "inst_course_offering_exercises_inst_exercise_id_fk"
  add_foreign_key "inst_module_section_exercises", "inst_exercises"
  add_foreign_key "inst_module_section_exercises", "inst_module_sections"
  add_foreign_key "inst_module_section_exercises", "inst_module_versions"
  add_foreign_key "inst_module_sections", "inst_module_versions"
  add_foreign_key "inst_module_versions", "course_offerings"
  add_foreign_key "inst_module_versions", "inst_modules"
  add_foreign_key "inst_modules", "inst_module_versions", column: "current_version_id"
  add_foreign_key "inst_sections", "inst_chapter_modules", name: "inst_sections_inst_chapter_module_id_fk"
  add_foreign_key "inst_sections", "inst_modules", name: "inst_sections_inst_module_id_fk"
  add_foreign_key "lms_accesses", "lms_instances", name: "lms_accesses_lms_instance_id_fk"
  add_foreign_key "lms_accesses", "users", name: "lms_accesses_user_id_fk"
  add_foreign_key "lms_instances", "lms_types", name: "lms_instances_lms_type_id_fk"
  add_foreign_key "lms_instances", "organizations", name: "lms_instances_organization_id_fk"
  add_foreign_key "odsa_book_progresses", "inst_books", name: "odsa_book_progresses_inst_book_id_fk"
  add_foreign_key "odsa_book_progresses", "users", name: "odsa_book_progresses_user_id_fk"
  add_foreign_key "odsa_exercise_attempts", "inst_book_section_exercises", name: "odsa_exercise_attempts_inst_book_section_exercise_id_fk"
  add_foreign_key "odsa_exercise_attempts", "inst_books", name: "odsa_exercise_attempts_inst_book_id_fk"
  add_foreign_key "odsa_exercise_attempts", "inst_course_offering_exercises", name: "odsa_exercise_attempts_inst_course_offering_exercise_id_fk"
  add_foreign_key "odsa_exercise_attempts", "inst_module_section_exercises"
  add_foreign_key "odsa_exercise_attempts", "inst_sections", name: "odsa_exercise_attempts_inst_section_id_fk"
  add_foreign_key "odsa_exercise_attempts", "users", name: "odsa_exercise_attempts_user_id_fk"
  add_foreign_key "odsa_exercise_progresses", "inst_book_section_exercises", name: "odsa_exercise_progresses_inst_book_section_exercise_id_fk"
  add_foreign_key "odsa_exercise_progresses", "inst_course_offering_exercises", name: "odsa_exercise_progresses_inst_course_offering_exercise_id_fk"
  add_foreign_key "odsa_exercise_progresses", "inst_module_section_exercises"
  add_foreign_key "odsa_exercise_progresses", "lms_accesses"
  add_foreign_key "odsa_exercise_progresses", "users", name: "odsa_exercise_progresses_user_id_fk"
  add_foreign_key "odsa_module_progresses", "inst_books", name: "odsa_module_progresses_inst_book_id_fk"
  add_foreign_key "odsa_module_progresses", "inst_chapter_modules", name: "odsa_module_progresses_inst_chapter_module_id_fk"
  add_foreign_key "odsa_module_progresses", "inst_module_versions"
  add_foreign_key "odsa_module_progresses", "lms_accesses", name: "odsa_module_progresses_lms_access_id_fk"
  add_foreign_key "odsa_module_progresses", "users", name: "odsa_module_progresses_user_id_fk"
  add_foreign_key "odsa_student_extensions", "inst_sections", name: "odsa_student_extensions_inst_section_id_fk"
  add_foreign_key "odsa_student_extensions", "users", name: "odsa_student_extensions_user_id_fk"
  add_foreign_key "odsa_user_interactions", "inst_book_section_exercises", name: "odsa_user_interactions_inst_book_section_exercise_id_fk"
  add_foreign_key "odsa_user_interactions", "inst_books", name: "odsa_user_interactions_inst_book_id_fk"
  add_foreign_key "odsa_user_interactions", "inst_course_offering_exercises", name: "odsa_user_interactions_inst_course_offering_exercise_id_fk"
  add_foreign_key "odsa_user_interactions", "inst_module_section_exercises"
  add_foreign_key "odsa_user_interactions", "inst_module_versions"
  add_foreign_key "odsa_user_interactions", "inst_sections", name: "odsa_user_interactions_inst_section_id_fk"
  add_foreign_key "odsa_user_interactions", "users", name: "odsa_user_interactions_user_id_fk"
  add_foreign_key "odsa_user_time_trackings", "inst_book_section_exercises", name: "odsa_user_time_tracking_inst_book_section_exercise_id_fk"
  add_foreign_key "odsa_user_time_trackings", "inst_books", name: "odsa_user_time_tracking_inst_book_id_fk"
  add_foreign_key "odsa_user_time_trackings", "inst_chapters", name: "odsa_user_time_tracking_inst_chapter_id_fk"
  add_foreign_key "odsa_user_time_trackings", "inst_course_offering_exercises", name: "odsa_user_time_tracking_inst_course_offering_exercise_id_fk"
  add_foreign_key "odsa_user_time_trackings", "inst_module_section_exercises", name: "odsa_user_time_tracking_inst_module_section_exercise_id_fk"
  add_foreign_key "odsa_user_time_trackings", "inst_module_versions", name: "odsa_user_time_tracking_inst_module_version_id_fk"
  add_foreign_key "odsa_user_time_trackings", "inst_modules", name: "odsa_user_time_tracking_inst_module_id_fk"
  add_foreign_key "odsa_user_time_trackings", "inst_sections", name: "odsa_user_time_tracking_inst_section_id_fk"
  add_foreign_key "odsa_user_time_trackings", "users", name: "odsa_user_time_tracking_user_id_fk"
  add_foreign_key "users", "global_roles", name: "users_global_role_id_fk"
  add_foreign_key "users", "time_zones", name: "users_time_zone_id_fk"
end
