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

ActiveRecord::Schema[7.1].define(version: 2025_03_21_102514) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "gift_ideas", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.decimal "price"
    t.string "link"
    t.string "image_url"
    t.bigint "created_by_id", null: false
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "buyer_id"
    t.index ["buyer_id"], name: "index_gift_ideas_on_buyer_id"
    t.index ["created_by_id"], name: "index_gift_ideas_on_created_by_id"
  end

  create_table "gift_recipients", force: :cascade do |t|
    t.bigint "gift_idea_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gift_idea_id", "user_id"], name: "index_gift_recipients_on_gift_idea_id_and_user_id", unique: true
    t.index ["gift_idea_id"], name: "index_gift_recipients_on_gift_idea_id"
    t.index ["user_id"], name: "index_gift_recipients_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invitations", force: :cascade do |t|
    t.string "token", null: false
    t.bigint "group_id", null: false
    t.bigint "created_by_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_invitations_on_created_by_id"
    t.index ["group_id"], name: "index_invitations_on_group_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti"
    t.datetime "exp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "group_id", null: false
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_memberships_on_group_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name", null: false
    t.date "birthday"
    t.string "gender"
    t.string "phone_number"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "locale"
    t.boolean "newsletter_subscription", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["newsletter_subscription"], name: "index_users_on_newsletter_subscription"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "gift_ideas", "users", column: "buyer_id"
  add_foreign_key "gift_ideas", "users", column: "created_by_id"
  add_foreign_key "gift_recipients", "gift_ideas"
  add_foreign_key "gift_recipients", "users"
  add_foreign_key "invitations", "groups"
  add_foreign_key "invitations", "users", column: "created_by_id"
  add_foreign_key "memberships", "groups"
  add_foreign_key "memberships", "users"
end
