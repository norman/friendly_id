source :rubygems

# platform :jruby do
#   gem "activerecord-jdbc-adapter", :git => "https://github.com/nicksieger/activerecord-jdbc-adapter.git"
#   gem "activerecord-jdbcmysql-adapter"
#   gem "activerecord-jdbcpostgresql-adapter"
#   gem "activerecord-jdbcsqlite3-adapter"
# end

platform :ruby do
  gem "mysql2"
  gem "pg"
  gem "sqlite3"
end

gem "activerecord", "~> 3.1.0"
gem "railties", "~> 3.1.3"
gem "ffaker"
gem "minitest"
gem "mocha"
gem "rake"
