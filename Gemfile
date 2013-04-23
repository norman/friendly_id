source 'https://rubygems.org'

gemspec

# Database Configuration
group :development, :test do
  platforms :jruby do
    gem 'activerecord-jdbcsqlite3-adapter'
    gem 'jruby-openssl'
  end

  platforms :ruby do
    gem 'sqlite3'
  end
end
