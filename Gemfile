source "https://rubygems.org"

gemspec

gem "standard"
gem "rake"

group :development, :test do
  # Active Record is no longer a runtime dependency, so the default bundle names
  # it explicitly for the Active Record test suite.
  gem "activerecord", ">= 7.1"
  gem "railties", ">= 7.1"

  # For the ROM adapter's test suite. Kept out of the gemspec so that Rails-only
  # users do not install them, and out of gemfiles/Gemfile.rom.rb's reach so that
  # suite genuinely runs without Active Record.
  gem "rom-sql"

  platforms :ruby do
    gem "byebug"
    gem "pry"
  end

  platforms :jruby do
    gem "activerecord-jdbcsqlite3-adapter", ">= 1.3.0.beta2"
    gem "kramdown"
  end

  platforms :ruby, :rbx do
    gem "sqlite3"
    gem "redcarpet"
  end
end
