require 'rails/generators'
require "rails/generators/active_record"

# This generator adds a migration for the {FriendlyId::History
# FriendlyId::History} addon.
class FriendlyIdGenerator < ActiveRecord::Generators::Base
  # ActiveRecord::Generators::Base inherits from Rails::Generators::NamedBase which requires a NAME parameter for the
  # new table name. Our generator always uses 'friendly_id_slugs', so we just set a random name here.
  argument :name, type: :string, default: 'random_name'

  source_root File.expand_path('../../friendly_id', __FILE__)

  # Copies the migration template to db/migrate.
  def copy_files
    migration_template 'migration.rb', 'db/migrate/create_friendly_id_slugs.rb'
  end

end
