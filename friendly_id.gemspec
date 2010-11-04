require File.expand_path("../lib/friendly_id/version", __FILE__)

Gem::Specification.new do |s|
  s.authors           = ["Norman Clarke", "Adrian Mugnolo", "Emilio Tagua"]
  s.description       = <<-EOM
    FriendlyId is the "Swiss Army bulldozer" of slugging and permalink plugins
    for Ruby on Rails. It allows you to create pretty URL's and work with
    human-friendly strings as if they were numeric ids for ActiveRecord models.
  EOM
  s.email             = ["norman@njclarke.com", "adrian@mugnolo.com", "miloops@gmail.com"]
  s.files             = Dir["lib/**/*.rb", "lib/**/*.rake", "*.md", "MIT-LICENSE",
    "Rakefile", "rails/init.rb", "generators/**/*.*", "test/**/*.*",
    "extras/**/*.*" ]
  s.has_rdoc          = true
  s.homepage          = "http://norman.github.com/friendly_id"
  s.name              = "friendly_id"
  s.platform          = Gem::Platform::RUBY
  s.rubyforge_project = "friendly-id"
  s.summary           = "A comprehensive slugging and pretty-URL plugin."
  s.test_files        = Dir.glob "test/**/*_test.rb"
  s.version           = FriendlyId::Version::STRING

  s.add_dependency "babosa", "~> 0.2.0"
  s.add_development_dependency "activerecord", "~> 3.0.0"
  s.add_development_dependency "mocha", "~> 0.9"
  s.add_development_dependency "sqlite3-ruby", "~> 1"

end
