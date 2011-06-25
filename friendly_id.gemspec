# encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)

require "friendly_id/version"

Gem::Specification.new do |s|
  s.name              = "friendly_id"
  s.version           = FriendlyId::Version::STRING
  s.authors           = ["Norman Clarke"]
  s.email             = ["norman@njclarke.com"]
  s.homepage          = "http://norman.github.com/friendly_id"
  s.summary           = "A comprehensive slugging and pretty-URL plugin."
  s.rubyforge_project = "friendly_id"
  s.files             = `git ls-files`.split("\n")
  s.test_files        = `git ls-files -- {test}/*`.split("\n")
  s.require_paths     = ["lib"]

  s.add_development_dependency "activerecord", "~> 3.0"
  s.add_development_dependency "sqlite3", "~> 1.3"
  s.add_development_dependency "cutest", "~> 1.1.2"
  s.add_development_dependency "ffaker"
  s.add_development_dependency "yard"

  s.description       = <<-EOM
    FriendlyId is the "Swiss Army bulldozer" of slugging and permalink plugins
    for Ruby on Rails. It allows you to create pretty URL's and work with
    human-friendly strings as if they were numeric ids for ActiveRecord models.
  EOM
end
