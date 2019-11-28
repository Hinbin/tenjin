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

ActiveRecord::Schema.define(version: 2019_11_27_123005) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_customisations", force: :cascade do |t|
    t.bigint "customisation_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["customisation_id", "user_id"], name: "index_active_customisations_on_customisation_id_and_user_id", unique: true
    t.index ["customisation_id"], name: "index_active_customisations_on_customisation_id"
    t.index ["user_id"], name: "index_active_customisations_on_user_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "all_time_topic_scores", force: :cascade do |t|
    t.integer "score"
    t.bigint "user_id"
    t.bigint "topic_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["topic_id"], name: "index_all_time_topic_scores_on_topic_id"
    t.index ["user_id"], name: "index_all_time_topic_scores_on_user_id"
  end

  create_table "answers", force: :cascade do |t|
    t.bigint "question_id"
    t.string "text"
    t.boolean "correct"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "external_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "asked_questions", force: :cascade do |t|
    t.bigint "question_id"
    t.bigint "quiz_id"
    t.boolean "correct"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_asked_questions_on_question_id"
    t.index ["quiz_id"], name: "index_asked_questions_on_quiz_id"
  end

  create_table "challenge_progresses", force: :cascade do |t|
    t.bigint "challenge_id"
    t.bigint "user_id"
    t.integer "progress"
    t.boolean "completed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_id"], name: "index_challenge_progresses_on_challenge_id"
    t.index ["user_id"], name: "index_challenge_progresses_on_user_id"
  end

  create_table "challenges", force: :cascade do |t|
    t.integer "challenge_type"
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer "number_required"
    t.integer "points"
    t.bigint "topic_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["topic_id"], name: "index_challenges_on_topic_id"
  end

  create_table "classroom_winners", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "classroom_id"
    t.integer "score"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["classroom_id"], name: "index_classroom_winners_on_classroom_id"
    t.index ["user_id"], name: "index_classroom_winners_on_user_id"
  end

  create_table "classrooms", force: :cascade do |t|
    t.string "client_id", null: false
    t.string "name", null: false
    t.string "code"
    t.string "description"
    t.boolean "disabled"
    t.bigint "subject_id"
    t.bigint "school_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "enrollments_count"
    t.index ["school_id"], name: "index_classrooms_on_school_id"
    t.index ["subject_id"], name: "index_classrooms_on_subject_id"
  end

  create_table "customisation_unlocks", force: :cascade do |t|
    t.bigint "customisation_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["customisation_id"], name: "index_customisation_unlocks_on_customisation_id"
    t.index ["user_id"], name: "index_customisation_unlocks_on_user_id"
  end

  create_table "customisations", force: :cascade do |t|
    t.integer "customisation_type"
    t.integer "cost"
    t.string "name"
    t.string "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "enrollments", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "classroom_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id", "user_id"], name: "index_enrollments_on_classroom_id_and_user_id", unique: true
    t.index ["classroom_id"], name: "index_enrollments_on_classroom_id"
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "flagged_questions", force: :cascade do |t|
    t.bigint "question_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["question_id"], name: "index_flagged_questions_on_question_id"
    t.index ["user_id"], name: "index_flagged_questions_on_user_id"
  end

  create_table "homework_progresses", force: :cascade do |t|
    t.bigint "homework_id"
    t.bigint "user_id"
    t.integer "progress"
    t.boolean "completed"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["homework_id"], name: "index_homework_progresses_on_homework_id"
    t.index ["user_id"], name: "index_homework_progresses_on_user_id"
  end

  create_table "homeworks", force: :cascade do |t|
    t.bigint "classroom_id"
    t.bigint "topic_id"
    t.datetime "due_date"
    t.integer "required"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["classroom_id"], name: "index_homeworks_on_classroom_id"
    t.index ["topic_id"], name: "index_homeworks_on_topic_id"
  end

  create_table "leaderboard_awards", force: :cascade do |t|
    t.bigint "subject_id"
    t.bigint "user_id"
    t.bigint "school_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["school_id"], name: "index_leaderboard_awards_on_school_id"
    t.index ["subject_id"], name: "index_leaderboard_awards_on_subject_id"
    t.index ["user_id"], name: "index_leaderboard_awards_on_user_id"
  end

  create_table "lessons", force: :cascade do |t|
    t.string "title"
    t.integer "category"
    t.string "video_id"
    t.bigint "topic_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["topic_id"], name: "index_lessons_on_topic_id"
  end

  create_table "multipliers", force: :cascade do |t|
    t.integer "score"
    t.integer "multiplier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "question_statistics", force: :cascade do |t|
    t.integer "number_asked"
    t.integer "number_correct"
    t.bigint "question_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["question_id"], name: "index_question_statistics_on_question_id", unique: true
  end

  create_table "questions", force: :cascade do |t|
    t.bigint "topic_id"
    t.integer "question_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "external_id"
    t.bigint "lesson_id"
    t.boolean "active", default: true
    t.integer "flagged_questions_count"
    t.index ["lesson_id"], name: "index_questions_on_lesson_id"
    t.index ["topic_id"], name: "index_questions_on_topic_id"
  end

  create_table "quizzes", force: :cascade do |t|
    t.datetime "time_last_answered"
    t.integer "streak"
    t.integer "answered_correct"
    t.integer "num_questions_asked"
    t.bigint "user_id"
    t.bigint "subject_id"
    t.bigint "topic_id"
    t.boolean "active"
    t.integer "question_order", array: true
    t.boolean "counts_for_leaderboard"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subject_id"], name: "index_quizzes_on_subject_id"
    t.index ["topic_id"], name: "index_quizzes_on_topic_id"
    t.index ["user_id"], name: "index_quizzes_on_user_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.integer "resource_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
  end

  create_table "school_groups", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "schools", force: :cascade do |t|
    t.string "client_id", null: false
    t.string "name"
    t.string "token", null: false
    t.date "last_sync"
    t.integer "sync_status"
    t.boolean "permitted"
    t.bigint "school_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_schools_on_client_id", unique: true
    t.index ["school_group_id"], name: "index_schools_on_school_group_id"
  end

  create_table "subjects", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "external_id"
  end

  create_table "topic_scores", force: :cascade do |t|
    t.integer "score"
    t.bigint "user_id"
    t.bigint "topic_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["topic_id"], name: "index_topic_scores_on_topic_id"
    t.index ["user_id"], name: "index_topic_scores_on_user_id"
  end

  create_table "topics", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "subject_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "external_id"
    t.bigint "default_lesson_id"
    t.boolean "active", default: true
    t.index ["subject_id"], name: "index_topics_on_subject_id"
  end

  create_table "usage_statistics", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "topic_id"
    t.datetime "date"
    t.integer "quizzes_started"
    t.integer "time_spent_in_seconds"
    t.integer "questions_answered"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["topic_id"], name: "index_usage_statistics_on_topic_id"
    t.index ["user_id"], name: "index_usage_statistics_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "school_id"
    t.integer "role", null: false
    t.string "provider"
    t.string "upi"
    t.string "forename"
    t.string "surname"
    t.string "photo"
    t.string "type"
    t.integer "challenge_points"
    t.datetime "time_of_last_quiz"
    t.string "username"
    t.boolean "disabled"
    t.index ["school_id"], name: "index_users_on_school_id"
    t.index ["upi"], name: "index_users_on_upi"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
  end

  add_foreign_key "active_customisations", "customisations"
  add_foreign_key "active_customisations", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "all_time_topic_scores", "topics"
  add_foreign_key "all_time_topic_scores", "users"
  add_foreign_key "answers", "questions"
  add_foreign_key "challenge_progresses", "challenges"
  add_foreign_key "challenge_progresses", "users"
  add_foreign_key "challenges", "topics"
  add_foreign_key "classroom_winners", "classrooms"
  add_foreign_key "classroom_winners", "users"
  add_foreign_key "customisation_unlocks", "customisations"
  add_foreign_key "customisation_unlocks", "users"
  add_foreign_key "enrollments", "classrooms"
  add_foreign_key "enrollments", "users"
  add_foreign_key "flagged_questions", "questions"
  add_foreign_key "flagged_questions", "users"
  add_foreign_key "homework_progresses", "homeworks"
  add_foreign_key "homework_progresses", "users"
  add_foreign_key "homeworks", "classrooms"
  add_foreign_key "homeworks", "topics"
  add_foreign_key "leaderboard_awards", "schools"
  add_foreign_key "leaderboard_awards", "subjects"
  add_foreign_key "leaderboard_awards", "users"
  add_foreign_key "question_statistics", "questions"
  add_foreign_key "questions", "lessons"
  add_foreign_key "questions", "topics"
  add_foreign_key "quizzes", "topics"
  add_foreign_key "quizzes", "users"
  add_foreign_key "schools", "school_groups"
  add_foreign_key "topic_scores", "topics"
  add_foreign_key "topic_scores", "users"
  add_foreign_key "topics", "subjects"
  add_foreign_key "usage_statistics", "topics"
  add_foreign_key "usage_statistics", "users"
end
