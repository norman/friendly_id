source :rubygems

platform :jruby do
  gem "activerecord-jdbcmysql-adapter"
  gem "activerecord-jdbcpostgresql-adapter"
  gem "activerecord-jdbcsqlite3-adapter"
end

platform :ruby do
  gem "mysql", "~> 2.8.1"
  gem "pg", "~> 0.11.0"
  gem "sqlite3", "~> 1.3.4"
end

gem "activerecord", "3.0.9"
gem "minitest", "~> 2.4.0"
gem "mocha", "~> 0.9.12"
gem "rake"
