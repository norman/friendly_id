# FriendlyId Global Configuration
#
# Use this to set up shared configuration options for your entire application.
# Any of the configuration options shown here can also be applied to single
# models by passing arguments to the `friendly_id` class method or defining
# methods in your model.
#
# To learn more, check out the guide:
#
# http://norman.github.io/friendly_id/file.Guide.html

FriendlyId.defaults do |config|
  # ## Reserved Words
  #
  # Some words could conflict with Rails's routes when used as slugs, or are
  # undesirable to allow as slugs. Edit this list as needed for your app.
  config.use :reserved

  config.reserved_words = %w[new edit index session login logout users admin
    stylesheets assets javascripts images]

  # This adds an option to treat reserved words as conflicts rather than exceptions.
  # When there is no good candidate, a UUID will be appended, matching the existing
  # conflict behavior.

  # config.treat_reserved_as_conflict = true

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
  # This is significantly more convenient but may not be appropriate for
  # all applications, so you must explicitly opt-in to this behavior. You can
  # always also configure it on a per-model basis if you prefer.
  #
  # Something else to consider is that using the :finders addon boosts
  # performance because it will avoid Rails-internal code that makes runtime
  # calls to `Module.extend`.
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
  # By default, FriendlyId's :slugged addon expects the slug column to be named
  # 'slug', but you can change it if you wish.
  #
  # config.slug_column = 'slug'
  #
  # By default, slug has no size limit, but you can change it if you wish.
  #
  # config.slug_limit = 255
  #
  # When FriendlyId can not generate a unique ID from your base method, it appends
  # a UUID, separated by a single dash. You can configure the character used as the
  # separator. If you're upgrading from FriendlyId 4, you may wish to replace this
  # with two dashes.
  #
  # config.sequence_separator = '-'
  #
  # Note that you must use the :slugged addon **prior** to the line which
  # configures the sequence separator, or else FriendlyId will raise an undefined
  # method error.
  #
  #  ## Tips and Tricks
  #
  #  ### Controlling when slugs are generated
  #
  # As of FriendlyId 5.0, new slugs are generated only when the slug field is
  # nil, but if you're using a column as your base method can change this
  # behavior by overriding the `should_generate_new_friendly_id?` method that
  # FriendlyId adds to your model. The change below makes FriendlyId 5.0 behave
  # more like 4.0.
  # Note: Use(include) Slugged module in the config if using the anonymous module.
  # If you have `friendly_id :name, use: slugged` in the model, Slugged module
  # is included after the anonymous module defined in the initializer, so it
  # overrides the `should_generate_new_friendly_id?` method from the anonymous module.
  #
  # config.use :slugged
  # config.use Module.new {
  #   def should_generate_new_friendly_id?
  #     slug.blank? || <your_column_name_here>_changed?
  #   end
  # }
  #
  # FriendlyId uses Rails's `parameterize` method to generate slugs, but for
  # languages that don't use the Roman alphabet, that's not usually sufficient.
  # Here we use the Babosa library to transliterate Russian Cyrillic slugs to
  # ASCII. If you use this, don't forget to add "babosa" to your Gemfile.
  #
  # config.use Module.new {
  #   def normalize_friendly_id(text)
  #     text.to_slug.normalize! :transliterate => [:russian, :latin]
  #   end
  # }
end
