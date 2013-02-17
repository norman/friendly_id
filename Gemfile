source :rubygems

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

git 'git://github.com/rails/rails.git' do
  gem 'railties'
  gem 'activerecord'
  gem 'activemodel' # for globalize3
end

gem 'globalize3', :github => 'svenfuchs/globalize3', :branch => 'rails4'
