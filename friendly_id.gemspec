# encoding: utf-8
require File.expand_path("../lib/friendly_id/version", __FILE__)

Gem::Specification.new do |s|
  s.name              = "friendly_id"
  s.version           = FriendlyId::VERSION
  s.authors           = ["Norman Clarke", "Philip Arndt"]
  s.email             = ["norman@njclarke.com", "parndt@gmail.com"]
  s.homepage          = "http://github.com/norman/friendly_id"
  s.license           = 'MIT'
  s.summary           = "A comprehensive slugging and pretty-URL plugin."
  s.rubyforge_project = "friendly_id"
  s.files             = `git ls-files`.split("\n")
  s.test_files        = `git ls-files -- {test}/*`.split("\n")
  s.require_paths     = ["lib"]

  s.add_dependency "activerecord", ">= 3.0", "< 4.0"
  s.add_development_dependency "railties", ">= 3.0", "< 4.0"
  s.add_development_dependency "minitest", "~> 4.4.0"
  s.add_development_dependency "mocha", "~> 0.13.1"
  s.add_development_dependency "maruku"
  s.add_development_dependency "yard"
  s.add_development_dependency "i18n"
  s.add_development_dependency "ffaker"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "globalize3"

  s.description = <<-EOM
FriendlyId is the "Swiss Army bulldozer" of slugging and permalink plugins for
Ruby on Rails. It allows you to create pretty URLs and work with human-friendly
strings as if they were numeric ids for Active Record models.
EOM

  s.post_install_message = <<-EOM
NOTE: FriendlyId 4.x breaks compatibility with 3.x. If you're upgrading
from 3.x, please see this document:

http://norman.github.io/friendly_id/4.0/file.Guide.html

EOM

end
