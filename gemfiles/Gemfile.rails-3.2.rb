source :rubygems

platforms :jruby do
  gem 'activerecord-jdbcsqlite3-adapter'
  gem 'activerecord-jdbcmysql-adapter'
  gem 'activerecord-jdbcpostgresql-adapter'
  gem 'jruby-openssl'
end

platforms :ruby do
  gem 'sqlite3'
  gem 'mysql2'
  gem 'pg'
end

gem 'ffaker'
gem 'activerecord', '~> 3.2.0'
gem 'railties', '~> 3.2.0'
gem 'minitest', '3.2.0'
gem 'mocha'
gem 'rake'
