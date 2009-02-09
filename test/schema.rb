ActiveRecord::Schema.define(:version => 1) do

  create_table "posts", :force => true do |t|
    t.column "title", "string"
    t.column "content", "text"
    t.column "created_at", "datetime"
    t.column "updated_at", "datetime"
  end

  create_table "users", :force => true do |t|
    t.column "login", "string"
    t.column "email", "string"
    t.column "created_at", "datetime"
    t.column "updated_at", "datetime"
  end
  
  create_table "people", :force => true do |t|
    t.column "name", "string"
    t.column "country_id", "integer"
  end
  
  create_table "countries", :force => true do |t|
    t.column "name", "string"
  end

  create_table "slugs", :force => true do |t|
    t.column "name", "string"
    t.column "sluggable_id", "integer"
    t.column "sequence", "integer", :null       => false, :default => 1
    t.column "sluggable_type", "string", :limit => 40
    t.column "scope", "string", :limit          => 40
    t.column "created_at", "datetime"
  end

  add_index "slugs", ["sluggable_id"], :name           => "index_slugs_on_sluggable_id"
  add_index "slugs", ["name", "sluggable_type", "scope", "sequence"], :name => "index_slugs_on_n_s_s_and_s", :unique => true

end
