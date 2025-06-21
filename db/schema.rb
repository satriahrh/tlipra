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

ActiveRecord::Schema[8.0].define(version: 2025_06_21_160100) do
  create_table "followerships", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "follower_id", null: false
    t.bigint "followed_id", null: false
    t.string "status", default: "active"
    t.datetime "unfollowed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id"], name: "index_followerships_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_followerships_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_followerships_on_follower_id"
  end

  create_table "sleep_records", primary_key: ["id", "clock_in_at"], charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=InnoDB\n/*!50100 PARTITION BY RANGE (to_days(`clock_in_at`))\n(PARTITION p_20250616_to_20250622 VALUES LESS THAN (739790) ENGINE = InnoDB,\n PARTITION p_20250623_to_20250629 VALUES LESS THAN (739797) ENGINE = InnoDB,\n PARTITION p_20250630_to_20250706 VALUES LESS THAN (739804) ENGINE = InnoDB,\n PARTITION p_20250707_to_20250713 VALUES LESS THAN (739811) ENGINE = InnoDB,\n PARTITION p_20250714_to_20250720 VALUES LESS THAN (739818) ENGINE = InnoDB,\n PARTITION p_max VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */", force: :cascade do |t|
    t.bigint "id", null: false, auto_increment: true
    t.bigint "user_id", null: false
    t.datetime "clock_in_at", null: false
    t.datetime "clock_out_at"
    t.integer "duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["clock_in_at", "user_id", "duration"], name: "index_sleep_records_on_clock_user_duration"
    t.index ["user_id", "clock_in_at", "duration"], name: "index_sleep_records_on_user_id_and_clock_in_at_and_duration"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "followerships", "users", column: "followed_id"
  add_foreign_key "followerships", "users", column: "follower_id"
end
