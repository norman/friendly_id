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

  def create_initializer
    initializer 'friendly_id.rb' do
<<-END
# FriendlyId Global Configuration
#
# Use this to set up shared configuration options for your entire application.
#
FriendlyId.defaults do |config|
  # # FriendlyId Global Config
  #
  # To learn more, check out the guide:
  #
  # http://rubydoc.info/github/norman/friendly_id/master/file/Guide.md
  #
  # ## Reserved Words
  #
  # Some words could conflict with Rails's routes when used as slugs. By default,
  # forbid "new" and "edit".
  config.use :reserved
  config.reserved_words = %w(new edit)

  #  ## Friendly Finders
  #
  # Uncomment this to use friendly finders in all models. By default, if
  # you wish to find a record by its friendly id, you must do:
  #
  #    MyModel.friendly.find('foo')
  #
  # If you uncomment this, you can do:
  #
  #    MyModel.find('foo')
  #
  # This is significantly more convenient, but may not be appropriate for
  # all applications, so you must explicity opt-in to this behavior. You can
  # also configure it on a per-model basis if you prefer.
  #
  # config.use :finders
  #
  # ## Slugs
  #
  # Most applications will use the :slugged module everywhere. If you wish
  # to do so, uncomment the following line.
  #
  # config.use :slugged
  #
  #  ## Tips and Tricks
  #
  # The "use" method will add modules to your models, and can be a useful way
  # to extend FriendlyId.
  #
  #  ### Changing when slugs are generated
  #
  # For example, by here we set up an alternate logic for when to generate new
  # slugs by overriding FriendlyId's built-in method
  # `should_generate_new_friendly_id`. By default, slugs are generated only when
  # the base method returns `nil`, but here we change it to use Active Record's
  # dirty tracking to determine when to generate the slug. The example assumes
  # you are using a column "name" as the basis of your slug; if you use this,
  # make sure you change it to whatever is appropriate for your application.
  #
  # config.use Model.new {
  #   def should_generate_new_friendly_id?
  #     slug.blank? || name_changed?
  #   end
  # }
  #
  #
  # You can also override the built-in slugging method; by default FriendlyId uses
  # Rails's `parameterize` method, but for Russian slugs that's not usually suffient.
  # Here we use the Babosa library to transliterate Russian Cyrillic slugs to ASCII:
  #
  # require 'babosa'
  #
  # config.use Model.new {
  #   def normalize_friendly_id(text)
  #     text.to_slug.normalize! :transliterations => [:russian, :latin]
  #   end
  # }
end
END
    end
  end
end
