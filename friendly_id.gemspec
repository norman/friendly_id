require 'lib/friendly_id/version'

spec = Gem::Specification.new do |s|
  s.name              = "friendly_id"
  s.rubyforge_project = 'friendly-id'
  s.version           = FriendlyId::Version::STRING
  s.authors           = ['Norman Clarke', 'Adrian Mugnolo', 'Emilio Tagua']
  s.email             = ['norman@njclarke.com', 'adrian@mugnolo.com', 'miloops@gmail.com']
  s.homepage          = 'http://rdoc.info/projects/norman/friendly_id'
  s.summary           = "A comprehensive slugging and pretty-URL plugin for ActiveRecord."
  s.description       = <<-EOM
    FriendlyId is the "Swiss Army bulldozer" of slugging and permalink
    plugins for Ruby on Rails. It allows you to create pretty URL’s
    and work with human-friendly strings as if they were numeric ids for
    ActiveRecord models.
  EOM

  s.has_rdoc         = true
  s.rdoc_options     << "--main" << "README.rdoc"
  s.extra_rdoc_files = ["README.rdoc", "History.txt"]

  s.test_files       = Dir.glob 'test/*_test.rb'
  s.files            = Dir["lib/**/*.rb", "init.rb", "README.rdoc", "History.txt", "LICENSE",
                           "Rakefile", "generators/**/*.*", "test/**/*.*", "extras/**/*.*"]

  s.add_dependency 'activerecord', '>= 2.2.3'
  s.add_dependency 'activesupport', '>= 2.2.3'
  s.add_development_dependency 'contest'
  s.add_development_dependency 'sqlite3-ruby'
  s.add_development_dependency 'rcov'
  s.add_development_dependency 'yard'

  s.post_install_message = <<-EOM

    ***********************************************************

      If you are upgrading friendly_id, please run

          ./script/generate friendly_id --skip-migration

      in your Rails application to ensure that you have the
      latest friendly_id Rake tasks.

    ***********************************************************

  EOM
end
