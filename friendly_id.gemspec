Gem::Specification.new do |s|
  s.name = "friendly_id"
  s.version = "1.1"
  s.date = "2008-05-12"
  s.summary = "Rails plugin for using human/seo-friendly ids with ActiveRecord objects."
  s.email = "norman@randomba.org"
  s.homepage = "http://randomba.org"
  s.description = "A plugin for Ruby on Rails which allows you to work with human-friendly strings as well as numeric ids for ActiveRecords."
  s.has_rdoc = true
  s.authors = ["Norman Clarke", "Adrian Mugnolo"]
  s.files = [
    "Rakefile",
    "init.rb",
    "install.rb",
    "uninstall.rb",
    "generators/friendly_id_migration/friendly_id_migration_generator.rb",
    "generators/friendly_id_migration/templates/create_slugs.rb",
    "lib/friendly_id.rb",
    "lib/slug.rb",
    "tasks/friendly_id_tasks.rake"    
    ]
  s.test_files = [
    "test/database.yml",
    "test/fixtures/post.rb",
    "test/fixtures/posts.yml",
    "test/fixtures/slugs.yml",
    "test/fixtures/user.rb",
    "test/fixtures/users.yml",
    "test/schema.rb",
    "test/sluggable_test.rb",
    "test/test_helper.rb",
    "test/unique_column_test.rb"
  ]
  s.rdoc_options = ["--main", "README"]
  s.extra_rdoc_files = ["CHANGES", "README"]
end