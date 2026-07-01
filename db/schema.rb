# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_06_26_090001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "admins", id: :serial, force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "admin", null: false
    t.datetime "last_login_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
  end

  create_table "audit_logs", id: :serial, force: :cascade do |t|
    t.integer "admin_id"
    t.string "action", null: false
    t.string "resource_type", null: false
    t.integer "resource_id"
    t.jsonb "metadata", default: {}
    t.string "ip"
    t.datetime "created_at", null: false
    t.index ["admin_id", "created_at"], name: "index_audit_logs_on_admin_id"
    t.index ["resource_type", "resource_id"], name: "index_audit_logs_on_resource"
  end

  create_table "face_records", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "rekognition_face_id", null: false
    t.string "s3_bucket", null: false
    t.string "s3_key", null: false
    t.datetime "indexed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rekognition_face_id"], name: "index_face_records_on_rekognition_face_id", unique: true
    t.index ["user_id"], name: "index_face_records_on_user_id"
  end

  create_table "point_actions", id: :serial, force: :cascade do |t|
    t.string "action_key", null: false
    t.string "description", null: false
    t.integer "points", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_key"], name: "index_point_actions_on_action_key", unique: true
  end

  create_table "point_transactions", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "point_action_id", null: false
    t.integer "amount", null: false
    t.string "reference_id"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.index ["point_action_id"], name: "index_point_transactions_on_point_action_id"
    t.index ["user_id", "created_at"], name: "index_point_transactions_on_user_id"
  end

  create_table "teams", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "short_name"
    t.string "logo_url"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_teams_on_name", unique: true
    t.index ["short_name"], name: "index_teams_on_short_name", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "rut", null: false
    t.string "phone", null: false
    t.string "password_digest"
    t.integer "birth_month", null: false
    t.integer "birth_year", null: false
    t.string "photo_url", null: false
    t.jsonb "teams_ids", default: [], null: false
    t.jsonb "consents", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "referral_code"
    t.string "referred_by"
    t.boolean "phone_verified", default: false, null: false
    t.string "phone_verification_token"
    t.datetime "phone_verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "indexed_at"
    t.string "registration_status"
    t.index ["referral_code"], name: "index_users_on_referral_code"
    t.index ["rut"], name: "index_users_on_rut", unique: true
  end

  add_foreign_key "audit_logs", "admins"
  add_foreign_key "face_records", "users"
  add_foreign_key "point_transactions", "point_actions"
  add_foreign_key "point_transactions", "users"
end
