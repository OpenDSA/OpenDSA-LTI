# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.


ActiveRecord::Schema.define(version: 20200425231608) do
  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace",     limit: 255
    t.text     "body",          limit: 65535
    t.string   "resource_id",   limit: 255,   null: false
    t.string   "resource_type", limit: 255,   null: false
    t.bigint  "author_id",     limit: 4
    t.string   "author_type",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "course_enrollments", force: :cascade do |t|
    t.bigint "user_id",            limit: 4, null: false
    t.bigint "course_offering_id", limit: 4, null: false
    t.bigint "course_role_id",     limit: 4, null: false
  end

  add_index "course_enrollments", ["course_offering_id"], name: "index_course_enrollments_on_course_offering_id", using: :btree
  add_index "course_enrollments", ["course_role_id"], name: "index_course_enrollments_on_course_role_id", using: :btree
  add_index "course_enrollments", ["user_id", "course_offering_id"], name: "index_course_enrollments_on_user_id_and_course_offering_id", unique: true, using: :btree
  add_index "course_enrollments", ["user_id"], name: "index_course_enrollments_on_user_id", using: :btree

  create_table "course_offerings", force: :cascade do |t|
    t.bigint  "course_id",               limit: 4,                   null: false
    t.bigint  "term_id",                 limit: 4,                   null: false
    t.string   "label",                   limit: 255,                 null: false
    t.string   "url",                     limit: 255
    t.boolean  "self_enrollment_allowed",             default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "cutoff_date"
    t.bigint  "late_policy_id",          limit: 4
    t.bigint  "lms_instance_id",         limit: 4,                   null: false
    t.string   "lms_course_code",         limit: 255
    t.string   "lms_course_num",          limit: 255,                 null: false
    t.boolean  "archived",                            default: false
  end

  add_index "course_offerings", ["course_id"], name: "index_course_offerings_on_course_id", using: :btree
  add_index "course_offerings", ["late_policy_id"], name: "course_offerings_late_policy_id_fk", using: :btree
  add_index "course_offerings", ["lms_instance_id", "lms_course_num"], name: "index_course_offerings_on_lms_instance_id_and_lms_course_num", using: :btree
  add_index "course_offerings", ["term_id"], name: "index_course_offerings_on_term_id", using: :btree

  create_table "course_roles", force: :cascade do |t|
    t.string  "name",                       limit: 255,                 null: false
    t.boolean "can_manage_course",                      default: false, null: false
    t.boolean "can_manage_assignments",                 default: false, null: false
    t.boolean "can_grade_submissions",                  default: false, null: false
    t.boolean "can_view_other_submissions",             default: false, null: false
    t.boolean "builtin",                                default: false, null: false
  end

  create_table "courses", force: :cascade do |t|
    t.string   "name",            limit: 255, null: false
    t.string   "number",          limit: 255, null: false
    t.bigint  "organization_id", limit: 4,   null: false
    t.bigint  "user_id",         limit: 4,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug",            limit: 255, null: false
  end

  add_index "courses", ["organization_id"], name: "index_courses_on_organization_id", using: :btree
  add_index "courses", ["slug"], name: "index_courses_on_slug", using: :btree
  add_index "courses", ["user_id"], name: "index_courses_on_user_id", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.bigint  "priority",         limit: 4,     default: 0, null: false
    t.bigint  "attempts",         limit: 4,     default: 0, null: false
    t.text     "handler",          limit: 65535,             null: false
    t.text     "last_error",       limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",        limit: 255
    t.string   "queue",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "progress_stage",   limit: 255
    t.bigint  "progress_current", limit: 4,     default: 0
    t.bigint  "progress_max",     limit: 4,     default: 0
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "errors", force: :cascade do |t|
    t.string   "usable_type", limit: 255
    t.bigint  "usable_id",   limit: 4
    t.string   "class_name",  limit: 255
    t.text     "message",     limit: 65535
    t.text     "trace",       limit: 65535
    t.text     "target_url",  limit: 65535
    t.text     "referer_url", limit: 65535
    t.text     "params",      limit: 65535
    t.text     "user_agent",  limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "errors", ["class_name"], name: "index_errors_on_class_name", using: :btree
  add_index "errors", ["created_at"], name: "index_errors_on_created_at", using: :btree

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",           limit: 255, null: false
    t.bigint  "sluggable_id",   limit: 4,   null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope",          limit: 255
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "global_roles", force: :cascade do |t|
    t.string  "name",                          limit: 255,                 null: false
    t.boolean "can_manage_all_courses",                    default: false, null: false
    t.boolean "can_edit_system_configuration",             default: false, null: false
    t.boolean "builtin",                                   default: false, null: false
  end

  create_table "identities", force: :cascade do |t|
    t.bigint  "user_id",    limit: 4,   null: false
    t.string   "provider",   limit: 255, null: false
    t.string   "uid",        limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "identities", ["uid", "provider"], name: "index_identities_on_uid_and_provider", using: :btree
  add_index "identities", ["user_id"], name: "index_identities_on_user_id", using: :btree

  create_table "inst_book_section_exercises", force: :cascade do |t|
    t.bigint  "inst_book_id",     limit: 4,                                                  null: false
    t.bigint  "inst_section_id",  limit: 4,                                                  null: false
    t.bigint  "inst_exercise_id", limit: 4
    t.decimal  "points",                              precision: 5, scale: 2,                 null: false
    t.boolean  "required",                                                    default: false
    t.decimal  "threshold",                           precision: 5, scale: 2,                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "type"
    t.text     "options",          limit: 4294967295
  end

  add_index "inst_book_section_exercises", ["inst_book_id"], name: "inst_book_section_exercises_inst_book_id_fk", using: :btree
  add_index "inst_book_section_exercises", ["inst_exercise_id"], name: "inst_book_section_exercises_inst_exercise_id_fk", using: :btree
  add_index "inst_book_section_exercises", ["inst_section_id"], name: "inst_book_section_exercises_inst_section_id_fk", using: :btree

  create_table "inst_books", force: :cascade do |t|
    t.bigint  "course_offering_id", limit: 4
    t.bigint  "user_id",            limit: 4,                          null: false
    t.string   "title",              limit: 50,                         null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "template",                              default: false
    t.string   "desc",               limit: 255
    t.datetime "last_compiled"
    t.text     "options",            limit: 4294967295
    t.bigint  "book_type",          limit: 4
  end

  add_index "inst_books", ["course_offering_id"], name: "inst_books_course_offering_id_fk", using: :btree
  add_index "inst_books", ["user_id"], name: "inst_books_user_id_fk", using: :btree

  create_table "inst_chapter_modules", force: :cascade do |t|
    t.bigint  "inst_chapter_id",     limit: 4, null: false
    t.bigint  "inst_module_id",      limit: 4, null: false
    t.bigint  "module_position",     limit: 4
    t.bigint  "lms_module_item_id",  limit: 4
    t.bigint  "lms_section_item_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint  "lms_assignment_id",   limit: 4
  end

  add_index "inst_chapter_modules", ["inst_chapter_id"], name: "inst_chapter_modules_inst_chapter_id_fk", using: :btree
  add_index "inst_chapter_modules", ["inst_module_id"], name: "inst_chapter_modules_inst_module_id_fk", using: :btree

  create_table "inst_chapters", force: :cascade do |t|
    t.bigint  "inst_book_id",            limit: 4,   null: false
    t.string   "name",                    limit: 100, null: false
    t.string   "short_display_name",      limit: 45
    t.bigint  "position",                limit: 4
    t.bigint  "lms_chapter_id",          limit: 4
    t.bigint  "lms_assignment_group_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "inst_chapters", ["inst_book_id"], name: "inst_chapters_inst_book_id_fk", using: :btree

  create_table "inst_course_offering_exercises", force: :cascade do |t|
    t.bigint  "course_offering_id",  limit: 4,                                  null: false
    t.bigint  "inst_exercise_id",    limit: 4,                                  null: false
    t.string   "resource_link_id",    limit: 255
    t.string   "resource_link_title", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "threshold",                              precision: 5, scale: 2, null: false
    t.decimal  "points",                                 precision: 5, scale: 2, null: false
    t.text     "options",             limit: 4294967295
  end

  add_index "inst_course_offering_exercises", ["course_offering_id", "resource_link_id", "inst_exercise_id"], name: "index_inst_course_offering_exercises_on_course_offering_res", unique: true, using: :btree
  add_index "inst_course_offering_exercises", ["inst_exercise_id"], name: "inst_course_offering_exercises_inst_exercise_id_fk", using: :btree

  create_table "inst_exercises", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.string   "short_name",    limit: 255,   null: false
    t.string   "ex_type",       limit: 50
    t.string   "description",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "learning_tool", limit: 255
    t.string   "av_address",    limit: 512
    t.bigint  "width",         limit: 4
    t.bigint  "height",        limit: 4
    t.text     "links",         limit: 65535
    t.text     "scripts",       limit: 65535
  end

  add_index "inst_exercises", ["short_name"], name: "index_inst_exercises_on_short_name", unique: true, using: :btree

  create_table "inst_module_section_exercises", force: :cascade do |t|
    t.bigint  "inst_module_version_id", limit: 4,                                             null: false
    t.bigint  "inst_module_section_id", limit: 4,                                             null: false
    t.bigint  "inst_exercise_id",       limit: 4,                                             null: false
    t.decimal  "points",                               precision: 5, scale: 2,                 null: false
    t.boolean  "required",                                                     default: false
    t.decimal  "threshold",                            precision: 5, scale: 2,                 null: false
    t.text     "options",                limit: 65535
    t.datetime "created_at",                                                                   null: false
    t.datetime "updated_at",                                                                   null: false
  end

  add_index "inst_module_section_exercises", ["inst_exercise_id"], name: "fk_rails_9b61737c9f", using: :btree
  add_index "inst_module_section_exercises", ["inst_module_section_id"], name: "fk_rails_b320810099", using: :btree
  add_index "inst_module_section_exercises", ["inst_module_version_id"], name: "fk_rails_5c4fc2ff52", using: :btree

  create_table "inst_module_sections", force: :cascade do |t|
    t.bigint  "inst_module_version_id", limit: 4,                  null: false
    t.string   "name",                   limit: 255,                null: false
    t.boolean  "show",                               default: true
    t.string   "learning_tool",          limit: 255
    t.string   "resource_type",          limit: 255
    t.string   "resource_name",          limit: 255
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
  end

  add_index "inst_module_sections", ["inst_module_version_id"], name: "fk_rails_ff11275e48", using: :btree

  create_table "inst_module_versions", force: :cascade do |t|
    t.bigint  "inst_module_id",      limit: 4,                    null: false
    t.string   "name",                limit: 255,                  null: false
    t.string   "git_hash",            limit: 255,                  null: false
    t.string   "file_path",           limit: 4096,                 null: false
    t.boolean  "template",                         default: false
    t.bigint  "course_offering_id",  limit: 4
    t.string   "resource_link_id",    limit: 255
    t.string   "resource_link_title", limit: 512
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
  end

  add_index "inst_module_versions", ["course_offering_id", "resource_link_id"], name: "index_inst_module_versions_on_course_resource", unique: true, using: :btree
  add_index "inst_module_versions", ["inst_module_id"], name: "fk_rails_7e343b3134", using: :btree

  create_table "inst_modules", force: :cascade do |t|
    t.string   "path",               limit: 255, null: false
    t.string   "name",               limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint  "current_version_id", limit: 4
  end

  add_index "inst_modules", ["current_version_id"], name: "fk_rails_73d3622e40", using: :btree
  add_index "inst_modules", ["path"], name: "index_inst_modules_on_path", unique: true, using: :btree

  create_table "inst_sections", force: :cascade do |t|
    t.bigint  "inst_module_id",         limit: 4,                   null: false
    t.bigint  "inst_chapter_module_id", limit: 4,                   null: false
    t.string   "short_display_name",     limit: 50
    t.string   "name",                   limit: 255,                 null: false
    t.bigint  "position",               limit: 4
    t.boolean  "gradable",                           default: false
    t.datetime "soft_deadline"
    t.datetime "hard_deadline"
    t.bigint  "time_limit",             limit: 4
    t.boolean  "show",                               default: true
    t.bigint  "lms_item_id",            limit: 4
    t.bigint  "lms_assignment_id",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "learning_tool",          limit: 255
    t.string   "resource_type",          limit: 255
    t.string   "resource_name",          limit: 255
    t.boolean  "lms_posted"
    t.datetime "time_posted"
  end

  add_index "inst_sections", ["inst_chapter_module_id"], name: "inst_sections_inst_chapter_module_id_fk", using: :btree
  add_index "inst_sections", ["inst_module_id"], name: "inst_sections_inst_module_id_fk", using: :btree

  create_table "languages", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "late_policies", force: :cascade do |t|
    t.string   "name",         limit: 255, null: false
    t.bigint  "late_days",    limit: 4,   null: false
    t.bigint  "late_percent", limit: 4,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "late_policies", ["name"], name: "index_late_policies_on_name", unique: true, using: :btree

  create_table "learning_tools", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.string   "key",        limit: 255, null: false
    t.string   "secret",     limit: 255, null: false
    t.string   "launch_url", limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "learning_tools", ["name"], name: "index_learning_tools_on_name", unique: true, using: :btree

  create_table "lms_accesses", force: :cascade do |t|
    t.string   "access_token",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint  "lms_instance_id", limit: 4,   null: false
    t.bigint  "user_id",         limit: 4,   null: false
    t.string   "consumer_key",    limit: 255
    t.string   "consumer_secret", limit: 255
  end

  add_index "lms_accesses", ["lms_instance_id", "user_id"], name: "index_lms_accesses_on_lms_instance_id_and_user_id", unique: true, using: :btree
  add_index "lms_accesses", ["user_id"], name: "lms_accesses_user_id_fk", using: :btree

  create_table "lms_instances", force: :cascade do |t|
    t.string   "url",             limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint  "lms_type_id",     limit: 4
    t.string   "consumer_key",    limit: 255
    t.string   "consumer_secret", limit: 255
    t.bigint  "organization_id", limit: 4
  end

  add_index "lms_instances", ["lms_type_id"], name: "lms_instances_lms_type_id_fk", using: :btree
  add_index "lms_instances", ["organization_id"], name: "lms_instances_organization_id_fk", using: :btree
  add_index "lms_instances", ["url"], name: "index_lms_instances_on_url", unique: true, using: :btree

  create_table "lms_types", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "lms_types", ["name"], name: "index_lms_types_on_name", unique: true, using: :btree

  create_table "odsa_book_progresses", force: :cascade do |t|
    t.bigint  "user_id",              limit: 4,          null: false
    t.bigint  "inst_book_id",         limit: 4,          null: false
    t.text     "started_exercises",    limit: 4294967295, null: false
    t.text     "proficient_exercises", limit: 4294967295, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "odsa_book_progresses", ["inst_book_id"], name: "odsa_book_progresses_inst_book_id_fk", using: :btree
  add_index "odsa_book_progresses", ["user_id", "inst_book_id"], name: "index_odsa_book_progresses_on_user_id_and_inst_book_id", unique: true, using: :btree

  create_table "odsa_bugs", force: :cascade do |t|
    t.bigint  "user_id",        limit: 4,          null: false
    t.string   "os_family",      limit: 50,         null: false
    t.string   "browser_family", limit: 20,         null: false
    t.string   "title",          limit: 50,         null: false
    t.text     "description",    limit: 4294967295, null: false
    t.string   "screenshot",     limit: 100
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "odsa_exercise_attempts", force: :cascade do |t|
    t.bigint  "user_id",                          limit: 4,                           null: false
    t.bigint  "inst_book_id",                     limit: 4
    t.bigint  "inst_section_id",                  limit: 4
    t.bigint  "inst_book_section_exercise_id",    limit: 4
    t.boolean  "worth_credit",                                                         null: false
    t.datetime "time_done",                                                            null: false
    t.bigint  "time_taken",                       limit: 4,                           null: false
    t.bigint  "count_hints",                      limit: 4,                           null: false
    t.boolean  "hint_used",                                                            null: false
    t.decimal  "points_earned",                                precision: 5, scale: 2, null: false
    t.boolean  "earned_proficiency",                                                   null: false
    t.bigint  "count_attempts",                   limit: 8,                           null: false
    t.string   "ip_address",                       limit: 20,                          null: false
    t.string   "question_name",                    limit: 50,                          null: false
    t.string   "request_type",                     limit: 50
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "correct"
    t.decimal  "pe_score",                                     precision: 5, scale: 2
    t.bigint  "pe_steps_fixed",                   limit: 4
    t.bigint  "inst_course_offering_exercise_id", limit: 4
    t.bigint  "inst_module_section_exercise_id",  limit: 4
    t.string   "answer",                           limit: 255
  end

  add_index "odsa_exercise_attempts", ["inst_book_id"], name: "odsa_exercise_attempts_inst_book_id_fk", using: :btree
  add_index "odsa_exercise_attempts", ["inst_book_section_exercise_id"], name: "odsa_exercise_attempts_inst_book_section_exercise_id_fk", using: :btree
  add_index "odsa_exercise_attempts", ["inst_course_offering_exercise_id"], name: "odsa_exercise_attempts_inst_course_offering_exercise_id_fk", using: :btree
  add_index "odsa_exercise_attempts", ["inst_module_section_exercise_id"], name: "fk_rails_6944f2321b", using: :btree
  add_index "odsa_exercise_attempts", ["inst_section_id"], name: "odsa_exercise_attempts_inst_section_id_fk", using: :btree
  add_index "odsa_exercise_attempts", ["user_id"], name: "odsa_exercise_attempts_user_id_fk", using: :btree

  create_table "odsa_exercise_progresses", force: :cascade do |t|
    t.bigint  "user_id",                          limit: 4,   null: false
    t.bigint  "inst_book_section_exercise_id",    limit: 4
    t.bigint  "current_score",                    limit: 4,   null: false
    t.bigint  "highest_score",                    limit: 4,   null: false
    t.datetime "first_done",                                   null: false
    t.datetime "last_done",                                    null: false
    t.bigint  "total_correct",                    limit: 4,   null: false
    t.bigint  "total_worth_credit",               limit: 4,   null: false
    t.datetime "proficient_date",                              null: false
    t.string   "current_exercise",                 limit: 255
    t.string   "correct_exercises",                limit: 255
    t.string   "hinted_exercise",                  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint  "inst_course_offering_exercise_id", limit: 4
    t.string   "lis_outcome_service_url",          limit: 255
    t.string   "lis_result_sourcedid",             limit: 255
    t.bigint  "lms_access_id",                    limit: 4
    t.bigint  "inst_module_section_exercise_id",  limit: 4
  end

  add_index "odsa_exercise_progresses", ["inst_book_section_exercise_id"], name: "odsa_exercise_progresses_inst_book_section_exercise_id_fk", using: :btree
  add_index "odsa_exercise_progresses", ["inst_course_offering_exercise_id"], name: "odsa_exercise_progresses_inst_course_offering_exercise_id_fk", using: :btree
  add_index "odsa_exercise_progresses", ["inst_module_section_exercise_id"], name: "fk_rails_7b1bb7d31f", using: :btree
  add_index "odsa_exercise_progresses", ["lms_access_id"], name: "fk_rails_3327f6b532", using: :btree
  add_index "odsa_exercise_progresses", ["user_id", "inst_book_section_exercise_id"], name: "index_odsa_ex_prog_on_user_id_and_inst_bk_sec_ex_id", unique: true, using: :btree
  add_index "odsa_exercise_progresses", ["user_id", "inst_course_offering_exercise_id"], name: "index_odsa_exercise_prog_on_user_course_offering_exercise", unique: true, using: :btree
  add_index "odsa_exercise_progresses", ["user_id", "inst_module_section_exercise_id"], name: "index_odsa_ex_prog_on_user_module_sec_ex", unique: true, using: :btree

  create_table "odsa_module_progresses", force: :cascade do |t|
    t.bigint  "user_id",                 limit: 4,   null: false
    t.bigint  "inst_book_id",            limit: 4
    t.datetime "first_done",                          null: false
    t.datetime "last_done",                           null: false
    t.datetime "proficient_date",                     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint  "inst_chapter_module_id",  limit: 4
    t.string   "lis_outcome_service_url", limit: 255
    t.string   "lis_result_sourcedid",    limit: 255
    t.float    "current_score",           limit: 24,  null: false
    t.float    "highest_score",           limit: 24,  null: false
    t.bigint  "lms_access_id",           limit: 4
    t.bigint  "inst_module_version_id",  limit: 4
  end

  add_index "odsa_module_progresses", ["inst_book_id"], name: "odsa_module_progresses_inst_book_id_fk", using: :btree
  add_index "odsa_module_progresses", ["inst_chapter_module_id"], name: "odsa_module_progresses_inst_chapter_module_id_fk", using: :btree
  add_index "odsa_module_progresses", ["inst_module_version_id"], name: "fk_rails_38a9ac7560", using: :btree
  add_index "odsa_module_progresses", ["lms_access_id"], name: "odsa_module_progresses_lms_access_id_fk", using: :btree
  add_index "odsa_module_progresses", ["user_id", "inst_chapter_module_id"], name: "index_odsa_module_progress_on_user_and_module", unique: true, using: :btree
  add_index "odsa_module_progresses", ["user_id", "inst_module_version_id"], name: "index_odsa_mod_prog_on_user_mod_version", unique: true, using: :btree

  create_table "odsa_student_extensions", force: :cascade do |t|
    t.bigint  "user_id",         limit: 4
    t.bigint  "inst_section_id", limit: 4, null: false
    t.datetime "soft_deadline"
    t.datetime "hard_deadline"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint  "time_limit",      limit: 4
    t.datetime "opening_date"
  end

  add_index "odsa_student_extensions", ["inst_section_id"], name: "odsa_student_extensions_inst_section_id_fk", using: :btree
  add_index "odsa_student_extensions", ["user_id"], name: "odsa_student_extensions_user_id_fk", using: :btree

  create_table "odsa_user_interactions", force: :cascade do |t|
    t.bigint  "user_id",                          limit: 4,          null: false
    t.bigint  "inst_book_id",                     limit: 4
    t.bigint  "inst_section_id",                  limit: 4
    t.bigint  "inst_book_section_exercise_id",    limit: 4
    t.string   "name",                             limit: 50,         null: false
    t.text     "description",                      limit: 4294967295, null: false
    t.datetime "action_time",                                         null: false
    t.bigint  "uiid",                             limit: 8,          null: false
    t.string   "browser_family",                   limit: 20,         null: false
    t.string   "browser_version",                  limit: 20,         null: false
    t.string   "os_family",                        limit: 50,         null: false
    t.string   "os_version",                       limit: 20,         null: false
    t.string   "device",                           limit: 50,         null: false
    t.string   "ip_address",                       limit: 20,         null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint  "inst_course_offering_exercise_id", limit: 4
    t.bigint  "inst_chapter_module_id",           limit: 4
    t.bigint  "inst_module_version_id",           limit: 4
    t.bigint  "inst_module_section_exercise_id",  limit: 4
  end

  add_index "odsa_user_interactions", ["inst_book_id"], name: "odsa_user_interactions_inst_book_id_fk", using: :btree
  add_index "odsa_user_interactions", ["inst_book_section_exercise_id"], name: "odsa_user_interactions_inst_book_section_exercise_id_fk", using: :btree
  add_index "odsa_user_interactions", ["inst_chapter_module_id"], name: "index_odsa_user_interactions_on_inst_chapter_module", using: :btree
  add_index "odsa_user_interactions", ["inst_course_offering_exercise_id"], name: "odsa_user_interactions_inst_course_offering_exercise_id_fk", using: :btree
  add_index "odsa_user_interactions", ["inst_module_section_exercise_id"], name: "fk_rails_9d3d089a83", using: :btree
  add_index "odsa_user_interactions", ["inst_module_version_id"], name: "fk_rails_599b647d17", using: :btree
  add_index "odsa_user_interactions", ["inst_section_id"], name: "odsa_user_interactions_inst_section_id_fk", using: :btree
  add_index "odsa_user_interactions", ["user_id"], name: "odsa_user_interactions_user_id_fk", using: :btree

  create_table "organizations", force: :cascade do |t|
    t.string   "name",         limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "abbreviation", limit: 255
    t.string   "slug",         limit: 255, null: false
  end

  add_index "organizations", ["name"], name: "index_organizations_on_name", unique: true, using: :btree
  add_index "organizations", ["slug"], name: "index_organizations_on_slug", unique: true, using: :btree

  create_table "pi_attempts", force: :cascade do |t|
    t.bigint  "user_id",    limit: 4
    t.string   "frame_name", limit: 255
    t.bigint  "question",   limit: 4
    t.bigint  "correct",    limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "terms", force: :cascade do |t|
    t.bigint  "season",     limit: 4,   null: false
    t.date     "starts_on",              null: false
    t.date     "ends_on",                null: false
    t.bigint  "year",       limit: 4,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug",       limit: 255, null: false
  end

  add_index "terms", ["slug"], name: "index_terms_on_slug", unique: true, using: :btree
  add_index "terms", ["starts_on"], name: "index_terms_on_starts_on", using: :btree
  add_index "terms", ["year", "season"], name: "index_terms_on_year_and_season", using: :btree

  create_table "time_zones", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "zone",       limit: 255
    t.string   "display_as", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.bigint  "sign_in_count",          limit: 4,   default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name",             limit: 255
    t.string   "last_name",              limit: 255
    t.bigint  "global_role_id",         limit: 4,                null: false
    t.string   "avatar",                 limit: 255
    t.string   "slug",                   limit: 255,              null: false
    t.bigint  "time_zone_id",           limit: 4
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["global_role_id"], name: "index_users_on_global_role_id", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["slug"], name: "index_users_on_slug", unique: true, using: :btree
  add_index "users", ["time_zone_id"], name: "index_users_on_time_zone_id", using: :btree

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
  add_foreign_key "users", "global_roles", name: "users_global_role_id_fk"
  add_foreign_key "users", "time_zones", name: "users_time_zone_id_fk"
end
