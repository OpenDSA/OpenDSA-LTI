class CreateDatabaseStructure < ActiveRecord::Migration
  def self.up
    create_table "course_enrollments", force: :cascade do |t|
        t.integer  "user_id",            limit: 4, null: false
        t.integer  "course_offering_id", limit: 4, null: false
        t.integer  "course_role_id",     limit: 4, null: false
        t.datetime "created_at"
        t.datetime "updated_at"
      end

      add_index "course_enrollments", ["course_offering_id"], name: "index_course_enrollments_on_course_offering_id", using: :btree
      add_index "course_enrollments", ["course_role_id"], name: "index_course_enrollments_on_course_role_id", using: :btree
      add_index "course_enrollments", ["user_id"], name: "index_course_enrollments_on_user_id", using: :btree
      add_index "course_enrollments", ["user_id"], name: "index_course_enrollments_on_user_id_and_course_offering_id", unique: true, using: :btree

      create_table "course_offerings", force: :cascade do |t|
        t.integer  "course_id",               limit: 4,   null: false
        t.integer  "term_id",                 limit: 4,   null: false
        t.string   "label",                   limit: 255, null: false
        t.string   "url",                     limit: 255
        t.boolean  "self_enrollment_allowed"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.date     "cutoff_date"
        t.string   "lms_course_code",         limit: 45
        t.integer  "lms_course_id",           limit: 4
        t.integer  "late_policy_id",          limit: 4,   null: false
      end

      add_index "course_offerings", ["course_id"], name: "index_course_offerings_on_course_id", using: :btree
      add_index "course_offerings", ["late_policy_id"], name: "fk_course_offerings_late_policies1_idx", using: :btree
      add_index "course_offerings", ["term_id"], name: "index_course_offerings_on_term_id", using: :btree

      create_table "course_roles", force: :cascade do |t|
        t.string   "name",                       limit: 255,                 null: false
        t.boolean  "can_manage_course",                      default: false, null: false
        t.boolean  "can_manage_assignments",                 default: false, null: false
        t.boolean  "can_grade_submissions",                  default: false, null: false
        t.boolean  "can_view_other_submissions",             default: false, null: false
        t.boolean  "builtin",                                default: false, null: false
        t.datetime "created_at"
        t.datetime "updated_at"
      end

      create_table "courses", force: :cascade do |t|
        t.string   "name",            limit: 255, null: false
        t.string   "number",          limit: 255, null: false
        t.integer  "organization_id", limit: 4,   null: false
        t.datetime "created_at"
        t.datetime "updated_at"
        t.integer  "creator_id",      limit: 4
        t.string   "slug",            limit: 255, null: false
      end

      add_index "courses", ["organization_id"], name: "index_courses_on_organization_id", using: :btree
      add_index "courses", ["slug"], name: "index_courses_on_slug", using: :btree

      create_table "errors", force: :cascade do |t|
        t.string   "usable_type", limit: 255
        t.integer  "usable_id",   limit: 4
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

      create_table "exercises", force: :cascade do |t|
        t.string   "name",               limit: 50,         null: false
        t.string   "short_display_name", limit: 45
        t.string   "ex_type",            limit: 50,         null: false
        t.text     "description",        limit: 4294967295, null: false
        t.datetime "created_at",                            null: false
        t.datetime "updated_at",                            null: false
      end

      add_index "exercises", ["name"], name: "name_UNIQUE", unique: true, using: :btree

      create_table "global_roles", force: :cascade do |t|
        t.string   "name",                          limit: 255,                 null: false
        t.boolean  "can_manage_all_courses",                    default: false, null: false
        t.boolean  "can_edit_system_configuration",             default: false, null: false
        t.boolean  "builtin",                                   default: false, null: false
        t.datetime "created_at"
        t.datetime "updated_at"
      end

      create_table "inst_book_owners", force: :cascade do |t|
        t.integer  "cnf_book_role_id", limit: 4, null: false
        t.integer  "users_id",         limit: 4, null: false
        t.datetime "created_at",                 null: false
        t.datetime "updated_at",                 null: false
      end

      add_index "inst_book_owners", ["cnf_book_role_id"], name: "fk_cnf_book_users_cnf_book_roles1_idx", using: :btree
      add_index "inst_book_owners", ["users_id"], name: "fk_cnf_book_users_users1_idx", using: :btree

      create_table "inst_book_roles", force: :cascade do |t|
        t.string   "name",        limit: 45
        t.boolean  "can_modify",             default: true
        t.boolean  "can_compile",            default: true
        t.datetime "created_at",                            null: false
        t.datetime "updated_at",                            null: false
      end

      create_table "inst_book_section_exercises", force: :cascade do |t|
        t.integer  "inst_book_id",    limit: 4,                         null: false
        t.decimal  "points",                    precision: 5, scale: 2, null: false
        t.integer  "inst_section_id", limit: 4,                         null: false
        t.integer  "cnf_exercise_id", limit: 4,                         null: false
        t.datetime "created_at",                                        null: false
        t.datetime "updated_at",                                        null: false
      end

      add_index "inst_book_section_exercises", ["cnf_exercise_id"], name: "fk_inst_book_section_exercises_cnf_exercises1_idx", using: :btree
      add_index "inst_book_section_exercises", ["inst_book_id"], name: "book_id", unique: true, using: :btree
      add_index "inst_book_section_exercises", ["inst_book_id"], name: "opendsa_bookmoduleexercise_752eb95b", using: :btree
      add_index "inst_book_section_exercises", ["inst_section_id"], name: "fk_opendsa_bookmoduleexercise_odsa_module_sections1_idx", using: :btree

      create_table "inst_books", force: :cascade do |t|
        t.string   "title",              limit: 50, null: false
        t.string   "book_url",           limit: 80, null: false
        t.integer  "course_offering_id", limit: 4,  null: false
        t.integer  "cnf_book_id",        limit: 4,  null: false
        t.datetime "created_at",                    null: false
        t.datetime "updated_at",                    null: false
        t.integer  "cnf_book_users_id",  limit: 4,  null: false
      end

      add_index "inst_books", ["cnf_book_users_id"], name: "fk_inst_books_cnf_book_users1_idx", using: :btree
      add_index "inst_books", ["course_offering_id"], name: "fk_opendsa_books_course_offerings1_idx", using: :btree

      create_table "inst_chapter_modules", force: :cascade do |t|
        t.integer  "cnf_chapter_id",   limit: 4, null: false
        t.integer  "cnf_module_id",    limit: 4, null: false
        t.integer  "module_position",  limit: 4
        t.datetime "created_at",                 null: false
        t.datetime "updated_at",                 null: false
        t.integer  "inst_chapters_id", limit: 4, null: false
        t.integer  "inst_modules_id",  limit: 4, null: false
      end

      add_index "inst_chapter_modules", ["inst_chapters_id"], name: "fk_cnf_chapter_modules_inst_chapters1_idx", using: :btree
      add_index "inst_chapter_modules", ["inst_modules_id"], name: "fk_cnf_chapter_modules_inst_modules1_idx", using: :btree

      create_table "inst_chapters", force: :cascade do |t|
        t.string   "name",                    limit: 100, null: false
        t.string   "short_display_name",      limit: 45
        t.integer  "book_id",                 limit: 4,   null: false
        t.integer  "position",                limit: 4,   null: false
        t.integer  "lms_chapter_id",          limit: 4
        t.integer  "lms_assignment_group_id", limit: 4
        t.datetime "created_at",                          null: false
        t.datetime "updated_at",                          null: false
      end

      add_index "inst_chapters", ["book_id"], name: "book_id", unique: true, using: :btree
      add_index "inst_chapters", ["book_id"], name: "opendsa_bookchapter_752eb95b", using: :btree

      create_table "inst_sections", force: :cascade do |t|
        t.string   "short_display_name",     limit: 50,                         null: false
        t.text     "name",                   limit: 4294967295,                 null: false
        t.integer  "inst_module_id",         limit: 4,                          null: false
        t.integer  "position",               limit: 4
        t.boolean  "gradable",                                  default: false
        t.datetime "soft_deadline"
        t.datetime "hard_deadline"
        t.integer  "time_limit",             limit: 4
        t.datetime "created_at",                                                null: false
        t.datetime "updated_at",                                                null: false
        t.integer  "cnf_chapter_modules_id", limit: 4,                          null: false
      end

      add_index "inst_sections", ["cnf_chapter_modules_id"], name: "fk_inst_sections_cnf_chapter_modules1_idx", using: :btree
      add_index "inst_sections", ["inst_module_id"], name: "fk_odsa_module_sections_odsa_modules1_idx", using: :btree

      create_table "late_policies", force: :cascade do |t|
        t.string   "name",         limit: 45
        t.integer  "late_days",    limit: 4,  null: false
        t.integer  "late_percent", limit: 4,  null: false
        t.datetime "created_at"
        t.datetime "updated_at"
      end

      add_index "late_policies", ["name"], name: "name_UNIQUE", unique: true, using: :btree

      create_table "lms_access", force: :cascade do |t|
        t.integer  "users_id",        limit: 4,   null: false
        t.integer  "lms_instance_id", limit: 4,   null: false
        t.string   "access_token",    limit: 150
        t.datetime "created_at",                  null: false
        t.datetime "updated_at",                  null: false
      end

      add_index "lms_access", ["lms_instance_id"], name: "fk_lms_access_lms_instance1_idx", using: :btree
      add_index "lms_access", ["users_id"], name: "fk_lms_access_users1_idx", using: :btree

      create_table "lms_instance", force: :cascade do |t|
        t.string   "url",         limit: 45
        t.integer  "lms_type_id", limit: 4,  null: false
        t.datetime "created_at",             null: false
        t.datetime "updated_at",             null: false
      end

      add_index "lms_instance", ["lms_type_id"], name: "fk_lms_instance_lms_types1_idx", using: :btree

      create_table "lms_types", force: :cascade do |t|
        t.string   "name",       limit: 45
        t.datetime "created_at",            null: false
        t.datetime "updated_at",            null: false
      end

      create_table "modules", force: :cascade do |t|
        t.text     "name",               limit: 4294967295, null: false
        t.string   "short_display_name", limit: 50,         null: false
        t.integer  "position",           limit: 4
        t.datetime "created_at",                            null: false
        t.datetime "updated_at",                            null: false
      end

      create_table "odsa_book_progress", force: :cascade do |t|
        t.integer  "user_id",                  limit: 4,          null: false
        t.integer  "book_id",                  limit: 4,          null: false
        t.text     "started_exercises",        limit: 4294967295, null: false
        t.text     "all_proficient_exercises", limit: 4294967295, null: false
        t.integer  "users_id",                 limit: 4,          null: false
        t.datetime "created_at"
        t.datetime "updated_at"
      end

      add_index "odsa_book_progress", ["book_id"], name: "opendsa_userdata_752eb95b", using: :btree
      add_index "odsa_book_progress", ["user_id"], name: "opendsa_userdata_403f60f", using: :btree
      add_index "odsa_book_progress", ["users_id"], name: "fk_opendsa_userdata_users1_idx", using: :btree

      create_table "odsa_bugs", force: :cascade do |t|
        t.integer  "user_id",        limit: 4,          null: false
        t.string   "os_family",      limit: 50,         null: false
        t.string   "browser_family", limit: 20,         null: false
        t.string   "title",          limit: 50,         null: false
        t.text     "description",    limit: 4294967295, null: false
        t.string   "screenshot",     limit: 100
        t.datetime "created_at"
        t.datetime "updated_at"
      end

      create_table "odsa_exercise_attempts", force: :cascade do |t|
        t.integer  "user_id",                       limit: 4,                          null: false
        t.integer  "inst_book_section_exercise_id", limit: 4,                          null: false
        t.boolean  "correct",                                                          null: false
        t.datetime "time_done",                                                        null: false
        t.integer  "time_taken",                    limit: 4,                          null: false
        t.integer  "count_hints",                   limit: 4,                          null: false
        t.boolean  "hint_used",                                                        null: false
        t.decimal  "points_earned",                            precision: 5, scale: 2, null: false
        t.boolean  "earned_proficiency",                                               null: false
        t.integer  "count_attempts",                limit: 8,                          null: false
        t.string   "ip_address",                    limit: 20,                         null: false
        t.string   "ex_question",                   limit: 50,                         null: false
        t.datetime "created_at",                                                       null: false
        t.datetime "updated_at",                                                       null: false
      end

      add_index "odsa_exercise_attempts", ["inst_book_section_exercise_id"], name: "fk_opendsa_userexerciselog_opendsa_bookmoduleexercise1_idx", using: :btree
      add_index "odsa_exercise_attempts", ["user_id"], name: "fk_opendsa_userexerciselog_users1_idx", using: :btree

      create_table "odsa_exercise_progress", force: :cascade do |t|
        t.integer  "user_id",                       limit: 4,                         null: false
        t.integer  "streak",                        limit: 4,                         null: false
        t.integer  "longest_streak",                limit: 4,                         null: false
        t.datetime "first_done",                                                      null: false
        t.datetime "last_done",                                                       null: false
        t.integer  "total_done",                    limit: 4,                         null: false
        t.integer  "total_correct",                 limit: 4,                         null: false
        t.datetime "proficient_date",                                                 null: false
        t.decimal  "progress",                                precision: 5, scale: 2, null: false
        t.integer  "inst_book_section_exercise_id", limit: 4,                         null: false
        t.datetime "created_at",                                                      null: false
        t.datetime "updated_at",                                                      null: false
      end

      add_index "odsa_exercise_progress", ["inst_book_section_exercise_id"], name: "fk_opendsa_userexercise_opendsa_bookmoduleexercise1_idx", using: :btree
      add_index "odsa_exercise_progress", ["user_id"], name: "fk_opendsa_userexercise_users1_idx", using: :btree

      create_table "odsa_student_extensions", force: :cascade do |t|
        t.integer  "user_id",          limit: 4
        t.integer  "inst_sections_id", limit: 4, null: false
        t.datetime "soft_deadline"
        t.datetime "hard_deadline"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.integer  "time_limit",       limit: 4
        t.datetime "opening_date"
      end

      add_index "odsa_student_extensions", ["inst_sections_id"], name: "fk_odsa_student_extensions_inst_sections1_idx", using: :btree
      add_index "odsa_student_extensions", ["user_id"], name: "index_student_extensions_on_user_id", using: :btree

      create_table "odsa_user_interactions", force: :cascade do |t|
        t.integer  "inst_book_id",                   limit: 4,          null: false
        t.integer  "user_id",                        limit: 4,          null: false
        t.integer  "inst_section_id",                limit: 4,          null: false
        t.integer  "inst_book_section_exercises_id", limit: 4,          null: false
        t.string   "name",                           limit: 50,         null: false
        t.text     "description",                    limit: 4294967295, null: false
        t.datetime "action_time",                                       null: false
        t.integer  "uiid",                           limit: 8,          null: false
        t.string   "browser_family",                 limit: 20,         null: false
        t.string   "browser_version",                limit: 20,         null: false
        t.string   "os_family",                      limit: 50,         null: false
        t.string   "os_version",                     limit: 20,         null: false
        t.string   "device",                         limit: 50,         null: false
        t.string   "ip_address",                     limit: 20,         null: false
        t.datetime "created_at",                                        null: false
        t.datetime "updated_at",                                        null: false
      end

      add_index "odsa_user_interactions", ["inst_book_id"], name: "opendsa_userbutton_752eb95b", using: :btree
      add_index "odsa_user_interactions", ["inst_book_section_exercises_id"], name: "fk_odsa_user_interactions_odsa_book_section_exercises1_idx", using: :btree
      add_index "odsa_user_interactions", ["inst_section_id"], name: "fk_odsa_user_interactions_odsa_module_sections1_idx", using: :btree
      add_index "odsa_user_interactions", ["user_id"], name: "fk_opendsa_userbutton_users1_idx", using: :btree

      create_table "odsa_user_module", force: :cascade do |t|
        t.integer  "user_id",         limit: 4, null: false
        t.integer  "inst_book_id",    limit: 4, null: false
        t.integer  "inst_module_id",  limit: 4, null: false
        t.datetime "first_done",                null: false
        t.datetime "last_done",                 null: false
        t.datetime "proficient_date",           null: false
        t.datetime "created_at",                null: false
        t.datetime "updated_at",                null: false
      end

      add_index "odsa_user_module", ["inst_book_id"], name: "opendsa_usermodule_752eb95b", using: :btree
      add_index "odsa_user_module", ["inst_module_id"], name: "opendsa_usermodule_ac126a2", using: :btree
      add_index "odsa_user_module", ["user_id"], name: "fk_opendsa_usermodule_users1_idx", using: :btree

      create_table "organizations", force: :cascade do |t|
        t.string   "name",         limit: 255, null: false
        t.datetime "created_at"
        t.datetime "updated_at"
        t.string   "abbreviation", limit: 255
        t.string   "slug",         limit: 255, null: false
      end

      add_index "organizations", ["name"], name: "index_organizations_on_name", unique: true, using: :btree
      add_index "organizations", ["slug"], name: "index_organizations_on_slug", unique: true, using: :btree

      create_table "terms", force: :cascade do |t|
        t.integer  "season",     limit: 4,   null: false
        t.date     "starts_on",              null: false
        t.date     "ends_on",                null: false
        t.integer  "year",       limit: 4,   null: false
        t.datetime "created_at"
        t.datetime "updated_at"
        t.string   "slug",       limit: 255, null: false
      end

      add_index "terms", ["slug"], name: "index_terms_on_slug", unique: true, using: :btree
      add_index "terms", ["starts_on"], name: "index_terms_on_starts_on", using: :btree
      add_index "terms", ["year"], name: "index_terms_on_year_and_season", using: :btree

      create_table "time_zones", force: :cascade do |t|
        t.string   "name",       limit: 255
        t.string   "zone",       limit: 255
        t.string   "display_as", limit: 255
        t.datetime "created_at"
        t.datetime "updated_at"
      end

      add_column :users, :global_role_id, :integer
      add_column :users, :time_zone_id, :integer

      add_index "users", ["global_role_id"], name: "index_users_on_global_role_id", using: :btree
      add_index "users", ["time_zone_id"], name: "index_users_on_time_zone_id", using: :btree

      add_foreign_key "course_enrollments", "course_offerings", name: "course_enrollments_course_offering_id_fk"
      add_foreign_key "course_enrollments", "course_roles", name: "course_enrollments_course_role_id_fk"
      add_foreign_key "course_enrollments", "users", name: "course_enrollments_user_id_fk"
      add_foreign_key "course_offerings", "courses", name: "course_offerings_course_id_fk"
      add_foreign_key "course_offerings", "late_policies", name: "fk_course_offerings_late_policies1"
      add_foreign_key "course_offerings", "terms", name: "course_offerings_term_id_fk"
      add_foreign_key "courses", "organizations", name: "courses_organization_id_fk"
      add_foreign_key "inst_book_owners", "inst_book_roles", column: "cnf_book_role_id", name: "fk_cnf_book_users_cnf_book_roles1"
      add_foreign_key "inst_book_owners", "users", column: "users_id", name: "fk_cnf_book_users_users1"
      add_foreign_key "inst_book_section_exercises", "exercises", column: "cnf_exercise_id", name: "fk_inst_book_section_exercises_cnf_exercises1"
      add_foreign_key "inst_book_section_exercises", "inst_books", name: "book_id_refs_id_1d50a4ed"
      add_foreign_key "inst_book_section_exercises", "inst_sections", name: "fk_opendsa_bookmoduleexercise_odsa_module_sections1"
      add_foreign_key "inst_books", "course_offerings", name: "fk_opendsa_books_course_offerings1"
      add_foreign_key "inst_books", "inst_book_owners", column: "cnf_book_users_id", name: "fk_inst_books_cnf_book_users1"
      add_foreign_key "inst_chapter_modules", "inst_chapters", column: "inst_chapters_id", name: "fk_cnf_chapter_modules_inst_chapters1"
      add_foreign_key "inst_chapter_modules", "modules", column: "inst_modules_id", name: "fk_cnf_chapter_modules_inst_modules1"
      add_foreign_key "inst_chapters", "inst_books", column: "book_id", name: "book_id_refs_id_19a809ad"
      add_foreign_key "inst_sections", "inst_chapter_modules", column: "cnf_chapter_modules_id", name: "fk_inst_sections_cnf_chapter_modules1"
      add_foreign_key "inst_sections", "modules", column: "inst_module_id", name: "fk_odsa_module_sections_odsa_modules1"
      add_foreign_key "lms_access", "lms_instance", name: "fk_lms_access_lms_instance1"
      add_foreign_key "lms_access", "users", column: "users_id", name: "fk_lms_access_users1"
      add_foreign_key "lms_instance", "lms_types", name: "fk_lms_instance_lms_types1"
      add_foreign_key "odsa_book_progress", "inst_books", column: "book_id", name: "book_id_refs_id_2e998b29"
      add_foreign_key "odsa_book_progress", "users", column: "users_id", name: "fk_opendsa_userdata_users1"
      add_foreign_key "odsa_exercise_attempts", "inst_book_section_exercises", name: "fk_opendsa_userexerciselog_opendsa_bookmoduleexercise1"
      add_foreign_key "odsa_exercise_attempts", "users", name: "fk_opendsa_userexerciselog_users1"
      add_foreign_key "odsa_exercise_progress", "inst_book_section_exercises", name: "fk_opendsa_userexercise_opendsa_bookmoduleexercise1"
      add_foreign_key "odsa_exercise_progress", "users", name: "fk_opendsa_userexercise_users1"
      add_foreign_key "odsa_student_extensions", "inst_sections", column: "inst_sections_id", name: "fk_odsa_student_extensions_inst_sections1"
      add_foreign_key "odsa_student_extensions", "users", name: "student_extensions_user_id_fk0"
      add_foreign_key "odsa_user_interactions", "inst_book_section_exercises", column: "inst_book_section_exercises_id", name: "fk_odsa_user_interactions_odsa_book_section_exercises1"
      add_foreign_key "odsa_user_interactions", "inst_books", name: "book_id_refs_id_5ab2753"
      add_foreign_key "odsa_user_interactions", "inst_sections", name: "fk_odsa_user_interactions_odsa_module_sections1"
      add_foreign_key "odsa_user_interactions", "users", name: "fk_opendsa_userbutton_users1"
      add_foreign_key "odsa_user_module", "inst_books", name: "book_id_refs_id_4a9a3cd7"
      add_foreign_key "odsa_user_module", "modules", column: "inst_module_id", name: "module_id_refs_id_24f2d578"
      add_foreign_key "odsa_user_module", "users", name: "fk_opendsa_usermodule_users1"
      add_foreign_key "users", "global_roles", name: "users_global_role_id_fk"
      add_foreign_key "users", "time_zones", name: "users_time_zone_id_fk"
  end

  def self.down
    # drop all the tables if you really need
    # to support migration back to version 0
  end
end
