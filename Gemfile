source 'http://rubygems.org'

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

# For globalize3 supporting rails4
gem 'globalize3', :github => 'svenfuchs/globalize3', :branch => 'rails4'
# forking off airblade/paper_trail to use the rails4 branch.
gem 'paper_trail', :github => 'airblade/paper_trail', :branch => 'rails4'
# for https://github.com/bmabey/database_cleaner/pull/153
gem 'database_cleaner', :github => 'bmabey/database_cleaner', :branch => 'master'
