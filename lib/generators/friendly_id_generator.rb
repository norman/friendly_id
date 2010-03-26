require 'rails/generators'
require 'rails/generators/migration'

class FriendlyIdGenerator < Rails::Generators::Base

  include Rails::Generators::Migration

  RAKE_FILE = File.join(File.dirname(__FILE__), "..", "friendly_id", "acktive_record", "tasks", "friendly_id.rake")
  MIGRATIONS_FILE = File.join(File.dirname(__FILE__), "..", "..", "generators", "friendly_id", "templates", "create_slugs.rb")

  class_option :"skip-migration", :type => :boolean, :desc => "Don't generate a migration for the slugs table"
  class_option :"skip-tasks", :type => :boolean, :desc => "Don't add friendly_id Rake tasks to lib/tasks"

  def copy_files(*args)
    migration_template MIGRATIONS_FILE, "db/migrate/create_slugs.rb" unless options["skip-migration"]
    rakefile "friendly_id.rake", File.read(RAKE_FILE) unless options["skip-tasks"]
  end

  # Taken from ActiveRecord's migration generator
  def self.next_migration_number(dirname) #:nodoc:
    if ActiveRecord::Base.timestamped_migrations
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    else
      "%.3d" % (current_migration_number(dirname) + 1)
    end
  end

end
