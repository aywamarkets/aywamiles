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

ActiveRecord::Schema.define(version: 2018_09_24_085315) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "administrators", force: :cascade do |t|
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
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "phone"
    t.string "photo_file_name"
    t.string "photo_content_type"
    t.bigint "photo_file_size"
    t.datetime "photo_updated_at"
    t.index ["email"], name: "index_administrators_on_email", unique: true
    t.index ["reset_password_token"], name: "index_administrators_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_administrators_on_unlock_token", unique: true
  end

  create_table "countries", force: :cascade do |t|
    t.string "name"
    t.string "iso_code_alpha_2"
    t.string "iso_code_num"
    t.string "country_calling_code"
    t.string "currency"
    t.string "language"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "partner_organizations", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "payment_network"
    t.string "status"
    t.integer "country_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_partner_organizations_on_country_id"
    t.index ["payment_network"], name: "index_partner_organizations_on_payment_network", unique: true
    t.index ["status"], name: "index_partner_organizations_on_status"
  end

  create_table "partners", force: :cascade do |t|
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
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "phone"
    t.integer "partner_organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_partners_on_email", unique: true
    t.index ["reset_password_token"], name: "index_partners_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_partners_on_unlock_token", unique: true
  end

end
