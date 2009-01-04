Gem::Specification.new do |s|
  s.name = %q{friendly_id}
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Norman Clarke", "Adrian Mugnolo", "Emilio Tagua"]
  s.cert_chain = ["/Users/norman/.gem/gem-public_cert.pem"]
  s.date = %q{2008-12-30}
  s.description = %q{A comprehensive slugging and pretty-URL plugin for Ruby on Rails.}
  s.email = ["norman@randomba.org", "adrian@randomba.org", "miloops@gmail.com"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt"]
  s.files = ["History.txt", "MIT-LICENSE", "Manifest.txt", "README.rdoc", "Rakefile", "friendly_id.gemspec", "generators/friendly_id/friendly_id_generator.rb", "generators/friendly_id/templates/create_slugs.rb", "generators/friendly_id_20_upgrade/friendly_id_20_upgrade_generator.rb", "generators/friendly_id_20_upgrade/templates/upgrade_friendly_id_to_20.rb", "init.rb", "lib/friendly_id.rb", "lib/friendly_id/helpers.rb", "lib/friendly_id/non_sluggable_class_methods.rb", "lib/friendly_id/non_sluggable_instance_methods.rb", "lib/friendly_id/shoulda_macros.rb", "lib/friendly_id/slug.rb", "lib/friendly_id/sluggable_class_methods.rb", "lib/friendly_id/sluggable_instance_methods.rb", "lib/friendly_id/version.rb", "lib/tasks/friendly_id.rake", "lib/tasks/friendly_id.rb", "test/database.yml", "test/fixtures/countries.yml", "test/fixtures/country.rb", "test/fixtures/people.yml", "test/fixtures/person.rb", "test/fixtures/post.rb", "test/fixtures/posts.yml", "test/fixtures/slugs.yml", "test/fixtures/user.rb", "test/fixtures/users.yml", "test/non_slugged_test.rb", "test/rails/2.x/app/controllers/application.rb", "test/rails/2.x/config/boot.rb", "test/rails/2.x/config/database.yml", "test/rails/2.x/config/environment.rb", "test/rails/2.x/config/environments/test.rb", "test/rails/2.x/config/routes.rb", "test/schema.rb", "test/scoped_model_test.rb", "test/slug_test.rb", "test/sluggable_test.rb", "test/test_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://randomba.org}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{friendly-id}
  s.rubygems_version = %q{1.3.1}
  s.signing_key = %q{/Users/norman/.gem/gem-private_key.pem}
  s.summary = %q{A comprehensive slugging and pretty-URL plugin for Ruby on Rails.}
  s.test_files = ["test/non_slugged_test.rb", "test/scoped_model_test.rb", "test/slug_test.rb", "test/sluggable_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<unicode>, [">= 0.1"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.2"])
    else
      s.add_dependency(%q<unicode>, [">= 0.1"])
      s.add_dependency(%q<hoe>, [">= 1.8.2"])
    end
  else
    s.add_dependency(%q<unicode>, [">= 0.1"])
    s.add_dependency(%q<hoe>, [">= 1.8.2"])
  end
end
