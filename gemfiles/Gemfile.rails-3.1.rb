source :rubygems

platform :jruby do
  gem "activerecord-jdbcmysql-adapter"
  gem "activerecord-jdbcpostgresql-adapter"
  gem "activerecord-jdbcsqlite3-adapter"
end

platform :ruby do
  gem "mysql2", "~> 0.3.6"
  gem "pg", "~> 0.11.0"
  gem "sqlite3", "~> 1.3.4"
end

gem "activerecord", "~> 3.1.0"
gem "minitest", "~> 2.4.0"
gem "mocha", "~> 0.9.12"
gem "rake"
