require File.expand_path("../lib/friendly_id/version", __FILE__)

Gem::Specification.new do |s|
  s.name = "friendly_id"
  s.version = FriendlyId::VERSION
  s.authors = ["Norman Clarke", "Philip Arndt"]
  s.email = ["norman@njclarke.com", "gems@p.arndt.io"]
  s.homepage = "https://github.com/norman/friendly_id"
  s.summary = "A comprehensive slugging and pretty-URL plugin."
  s.files = `git ls-files lib`.split($/) + ["Changelog.md", "MIT-LICENSE", "README.md"]
  s.require_paths = ["lib"]
  s.license = "MIT"

  # Verified green on 3.1. Note that Hanami 3.0 itself requires Ruby >= 3.3, so
  # Hanami users need that; the ROM adapter works on 3.1 for plain ROM apps.
  s.required_ruby_version = ">= 3.1.0"

  # No runtime dependency on any ORM. FriendlyId ships one adapter per
  # persistence library and you bring your own:
  #
  #   require "friendly_id/active_record"   # Rails
  #   require "friendly_id/rom"             # ROM, used by Hanami
  #
  # Requiring "friendly_id" loads the Active Record adapter when Active Record is
  # present, so Rails applications need no change.
  #
  # Active Record is deliberately not a development dependency either, so that
  # gemfiles/Gemfile.rom.rb resolves without it and the ROM adapter is proven to
  # work when Active Record is not installed at all. The Gemfiles that need it
  # name it themselves.
  s.add_development_dependency "babosa"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "minitest", "~> 5.3"
  s.add_development_dependency "mocha", "~> 2.1"
  s.add_development_dependency "yard"
  s.add_development_dependency "i18n"
  s.add_development_dependency "ffaker"
  s.add_development_dependency "simplecov"

  s.description = "FriendlyId is the \"Swiss Army bulldozer\" of slugging " \
    "and permalink plugins for Active Record. It lets you create pretty URLs " \
    "and work with human-friendly strings as if they were numeric ids."
end
