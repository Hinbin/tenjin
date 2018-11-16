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

ActiveRecord::Schema.define(version: 2018_11_11_170619) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "answers", force: :cascade do |t|
    t.bigint "question_id"
    t.string "text"
    t.boolean "correct"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "classrooms", force: :cascade do |t|
    t.string "client_id", null: false
    t.string "name"
    t.string "code"
    t.string "description"
    t.bigint "subject_id"
    t.bigint "school_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_classrooms_on_school_id"
    t.index ["subject_id"], name: "index_classrooms_on_subject_id"
  end

  create_table "default_subject_maps", force: :cascade do |t|
    t.string "name"
    t.bigint "subject_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subject_id"], name: "index_default_subject_maps_on_subject_id"
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

  create_table "permitted_schools", force: :cascade do |t|
    t.text "school_id"
    t.text "name"
    t.text "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "questions", force: :cascade do |t|
    t.bigint "topic_id"
    t.string "text"
    t.string "image"
    t.integer "answers_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["topic_id"], name: "index_questions_on_topic_id"
  end

  create_table "quizzes", force: :cascade do |t|
    t.datetime "time_last_answered"
    t.integer "streak"
    t.integer "answered_correct"
    t.integer "num_questions_asked"
    t.bigint "user_id"
    t.bigint "classroom_id"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id"], name: "index_quizzes_on_classroom_id"
    t.index ["user_id"], name: "index_quizzes_on_user_id"
  end

  create_table "schools", force: :cascade do |t|
    t.string "name"
    t.string "client_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_schools_on_client_id", unique: true
  end

  create_table "subject_maps", force: :cascade do |t|
    t.bigint "school_id"
    t.string "client_id"
    t.string "client_subject_name"
    t.bigint "subject_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_subject_maps_on_school_id"
    t.index ["subject_id"], name: "index_subject_maps_on_subject_id"
  end

  create_table "subjects", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "topics", force: :cascade do |t|
    t.string "name"
    t.bigint "subject_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subject_id"], name: "index_topics_on_subject_id"
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
    t.integer "role"
    t.string "provider"
    t.string "upi"
    t.string "forename"
    t.string "surname"
    t.string "photo"
    t.string "type"
    t.index ["school_id"], name: "index_users_on_school_id"
    t.index ["upi"], name: "index_users_on_upi", unique: true
  end

  add_foreign_key "answers", "questions"
  add_foreign_key "default_subject_maps", "subjects"
  add_foreign_key "enrollments", "classrooms"
  add_foreign_key "enrollments", "users"
  add_foreign_key "questions", "topics"
  add_foreign_key "quizzes", "users"
  add_foreign_key "subject_maps", "schools"
  add_foreign_key "subject_maps", "subjects"
  add_foreign_key "topics", "subjects"
end
