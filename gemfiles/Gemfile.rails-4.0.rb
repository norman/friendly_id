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
git 'git://github.com/rails/rails.git' do
  gem 'activerecord'
  gem 'railties'
end
if ENV['JOURNEY']
  gem 'journey', :path => ENV['JOURNEY']
else
  gem 'journey', :git => "git://github.com/rails/journey.git"
end

if ENV['AR_DEPRECATED_FINDERS']
  gem 'active_record_deprecated_finders', :path => ENV['AR_DEPRECATED_FINDERS']
else
  gem 'active_record_deprecated_finders', :git => 'git://github.com/rails/active_record_deprecated_finders.git'
end
gem 'minitest', '~> 3.2.0'
gem 'mocha'
gem 'rake'
gem 'globalize3', :git => 'git://github.com/svenfuchs/globalize3.git'
gem 'paper_trail', :git => 'git://github.com/parndt/paper_trail.git', :branch => 'rails4'