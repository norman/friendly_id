ActiveRecord::Schema.define(:version => 3) do

  create_table "posts", :force => true do |t|
    t.string   "name"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "slugs", :force => true do |t|
    t.string   "name"
    t.string   "sluggable_type"
    t.integer  "sluggable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "slugs", ["sluggable_id"], :name => "index_slugs_on_sluggable_id"
  add_index "slugs", ["name", "sluggable_type"], 
    :name => "index_slugs_on_name_and_sluggable_type", :unique => true

end
