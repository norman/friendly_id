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
    t.string "name"
    t.integer "sluggable_id"
    t.integer "sequence", :null       => false, :default => 1
    t.string "sluggable_type", :limit => 40
    t.string "scope", :limit          => 40
    t.datetime "created_at"
  end

  add_index "slugs", ["sluggable_id"], :name           => "index_slugs_on_sluggable_id"
  add_index "slugs", ["name", "sluggable_type", "scope", "sequence"], :name => "index_slugs_on_n_s_s_and_s", :unique => true

end
