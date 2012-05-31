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

git "git://github.com/rails/rails.git", :branch => "3-2-stable" do
  gem 'activerecord'
  gem 'railties'
end

gem 'ffaker'
gem 'minitest'
gem 'mocha'
gem 'rake'
gem 'globalize3'
