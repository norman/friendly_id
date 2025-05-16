source "https://rubygems.org"

gemspec path: "../"

gem "activerecord", "~> 7.2.0"
gem "railties", "~> 7.2.0"

# Database Configuration
group :development, :test do
  platforms :jruby do
    gem "activerecord-jdbcmysql-adapter", "~> 61.0"
    gem "activerecord-jdbcpostgresql-adapter", "~> 61.0"
    gem "kramdown"
  end

  platforms :ruby, :rbx do
    gem "sqlite3"
    gem "mysql2"
    gem "pg"
    gem "redcarpet"
  end
end
