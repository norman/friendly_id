source 'https://rubygems.org'

gemspec path: '../'

# Database Configuration
group :development, :test do
  platforms :jruby do
    gem 'activerecord-jdbcsqlite3-adapter', '>= 1.3.0.beta2'
    gem 'activerecord-jdbcmysql-adapter', '>= 1.3.0.beta2'
    gem 'activerecord-jdbcpostgresql-adapter', '>= 1.3.0.beta2'
    gem 'jruby-openssl'
  end

  platforms :ruby do
    gem 'sqlite3'
    gem 'mysql2'
    gem 'pg'
  end
end
