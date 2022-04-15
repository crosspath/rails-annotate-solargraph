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

ActiveRecord::Schema[7.0].define(version: 20220415102004) do
  create_table "books", force: :cascade do |t|
    t.text "hash"
    t.text "array"
    t.text "openstruct"
    t.integer "integer"
    t.decimal "price", precision: 12, scale: 4
    t.boolean "hard_cover"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
