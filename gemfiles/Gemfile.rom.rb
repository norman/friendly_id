source "https://rubygems.org"

gemspec path: "../"

# The ROM adapter must work without Active Record, so this bundle deliberately
# does not include it.
gem "rom-sql", "~> 3.7"
gem "babosa"

# The :simple_i18n addon needs an i18n source. This is the plain i18n gem, not
# Active Support's integration with it, which is the whole reason the addon works
# here at all. Hanami users can instead pass `i18n: Hanami.app["i18n"]`.
gem "i18n"

# The Rails gemfiles get rake transitively through railties; this one has no
# such path to it.
gem "rake"

group :development, :test do
  gem "sqlite3"
  gem "pg"
  gem "mysql2"
end
