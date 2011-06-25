require 'rails/generators'
require 'rails/generators/migration'

class FriendlyIdGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../../friendly_id', __FILE__)

  def copy_files(*args)
    migration_template 'migration.rb', 'db/migrate/create_friendly_id_slugs.rb'
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