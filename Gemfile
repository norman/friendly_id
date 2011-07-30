source :rubygems

platform :jruby do
  gem "activerecord-jdbcmysql-adapter"
  gem "activerecord-jdbcpostgresql-adapter"
  gem "activerecord-jdbcsqlite3-adapter"
end

platform :ruby do
  gem "mysql"
  gem "mysql2", ENV["DB_VERSION"] || "~> 0.2.11"
  gem "pg"
  gem "sqlite3"
end

gem "activerecord", ENV["AR"] || "3.0.9"

gem "ffaker"
gem "minitest"
gem "simplecov", :platform => :ruby_19
gem "maruku"
gem "yard"
gem "mocha"
