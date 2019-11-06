source 'https://rubygems.org'

gemspec path: '../'

gem 'activerecord', '~> 4.0.13'
gem 'railties', '~> 4.0.13'
gem 'minitest', '~> 4.5.0'

# Database Configuration
group :development, :test do
  platforms :jruby do
    gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.14'
    gem 'activerecord-jdbcmysql-adapter', '~> 1.3.14'
    gem 'activerecord-jdbcpostgresql-adapter', '~> 1.3.14'
    gem 'kramdown'
  end

  platforms :ruby, :rbx do
    gem 'sqlite3'
    gem 'mysql2', '~> 0.3.10'
    gem 'pg', '~> 0.15'
    gem 'redcarpet'
  end

  platforms :rbx do
    gem 'rubysl', '~> 2.0'
    gem 'rubinius-developer_tools'
    gem 'json'
  end
end
