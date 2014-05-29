source 'https://rubygems.org'

gemspec path: '../'

gem 'rails', github: 'rails/rails', branch: '4-1-stable' do
  gem 'activerecord'
  gem 'railties'
end

# Database Configuration
group :development, :test do
  platforms :jruby do
    gem 'activerecord-jdbcsqlite3-adapter', '>= 1.3.0.beta2'
    gem 'activerecord-jdbcmysql-adapter', '>= 1.3.0.beta2'
    gem 'activerecord-jdbcpostgresql-adapter', '>= 1.3.0.beta2'
    gem 'kramdown'
  end

  platforms :ruby, :rbx do
    gem 'sqlite3'
    gem 'mysql2'
    gem 'pg'
    gem 'redcarpet'
  end

  platforms :rbx do
    gem 'rubysl', '~> 2.0'
    gem 'rubinius-developer_tools'
  end
end
