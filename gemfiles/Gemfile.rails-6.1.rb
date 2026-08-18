source "https://rubygems.org"

gemspec path: "../"

gem "activerecord", "~> 6.1.4"
gem "railties", "~> 6.1.4"

# Database Configuration
group :development, :test do
  platforms :jruby do
    gem "activerecord-jdbcmysql-adapter", "~> 61.0"
    gem "activerecord-jdbcpostgresql-adapter", "~> 61.0"
    gem "kramdown"
  end

  platforms :ruby, :rbx do
    gem "redcarpet"
  end

  gem "sqlite3", platforms: [:ruby, :rbx] if !ENV["CI"] || ENV["DB"] == "sqlite3"
  gem "mysql2", platforms: [:ruby, :rbx] if !ENV["CI"] || ENV["DB"] == "mysql"
  gem "pg", platforms: [:ruby, :rbx] if !ENV["CI"] || ENV["DB"] == "postgresql"
end
