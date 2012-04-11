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

gem 'activerecord', '~> 3.1.0'
gem 'railties', '~> 3.1.3'
gem 'ffaker'
gem 'minitest'
gem 'mocha'
gem 'rake'
gem 'globalize3'