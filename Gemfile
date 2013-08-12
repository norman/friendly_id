source 'https://rubygems.org'

gemspec

# Database Configuration
group :development, :test do
  gem 'globalize3', github: 'svenfuchs/globalize3', branch: 'rails4'
  gem 'paper_trail', github: 'airblade/paper_trail', branch: 'master'

  platforms :jruby do
    gem 'activerecord-jdbcsqlite3-adapter', '>= 1.3.0.beta2'
    gem 'jruby-openssl'
  end

  platforms :ruby do
    gem 'sqlite3'
  end

  gem 'pry'
  gem 'pry-nav'
end
