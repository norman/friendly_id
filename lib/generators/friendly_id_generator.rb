require 'rails/generators'
require "rails/generators/active_record"

# This generator adds a migration for the {FriendlyId::History
# FriendlyId::History} addon.
class FriendlyIdGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  extend ActiveRecord::Generators::Migration if defined? ActiveRecord::Generators::Migration

  source_root File.expand_path('../../friendly_id', __FILE__)

  # Copies the migration template to db/migrate.
  def copy_files(*args)
    migration_template 'migration.rb', 'db/migrate/create_friendly_id_slugs.rb'
  end

end
