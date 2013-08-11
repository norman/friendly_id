require 'i18n'

module FriendlyId

=begin

== Translating Slugs Using Globalize

The {FriendlyId::Globalize Globalize} module lets you use
Globalize[https://github.com/svenfuchs/globalize3] to translate slugs. This
module is most suitable for applications that need to be localized to many
languages. If your application only needs to be localized to one or two
languages, you may wish to consider the {FriendlyId::SimpleI18n SimpleI18n}
module.

In order to use this module, your model's table and translation table must both
have a slug column, and your model must set the +slug+ field as translatable
with Globalize:

    class Post < ActiveRecord::Base
      translates :title, :slug
      extend FriendlyId
      friendly_id :title, :use => :globalize
    end

=== Finds

Finds will take the current locale into consideration:

  I18n.locale = :it
  Post.find("guerre-stellari")
  I18n.locale = :en
  Post.find("star-wars")

Additionally, finds will fall back to the default locale:

  I18n.locale = :it
  Post.find("star-wars")

To find a slug by an explicit locale, perform the find inside a block
passed to I18n's +with_locale+ method:

  I18n.with_locale(:it) { Post.find("guerre-stellari") }

=== Creating Records

When new records are created, the slug is generated for the current locale only.

=== Translating Slugs

To translate an existing record's friendly_id, use
{FriendlyId::Globalize::Model#set_friendly_id}. This will ensure that the slug
you add is properly escaped, transliterated and sequenced:

  post = Post.create :name => "Star Wars"
  post.set_friendly_id("Guerre stellari", :it)

If you don't pass in a locale argument, FriendlyId::Globalize will just use the
current locale:

  I18n.with_locale(:it) { post.set_friendly_id("Guerre stellari") }

=end
  module Globalize

    def self.included(model_class)
      model_class.friendly_id_config.instance_eval do
        self.class.send :include, Configuration
        self.slug_generator_class     ||= SlugGenerator
        defaults[:slug_column]        ||= 'slug'
        defaults[:sequence_separator] ||= '-'
      end
      model_class.before_validation :set_globalized_slug

      model_class.class_eval do
        # Check if slug field is enabled to be translated with Globalize
        unless respond_to?('translated_attribute_names') || translated_attribute_names.exclude?(friendly_id_config.query_field.to_sym)
          puts "\n[FriendlyId] You need to translate '#{friendly_id_config.query_field}' field with Globalize (add 'translates :#{friendly_id_config.query_field}' in your model '#{self.class.name}')\n\n"
        end
      end
    end

    def should_generate_new_friendly_id?
      translation_for(::Globalize.locale).send(friendly_id_config.slug_column).nil? &&
        !send(friendly_id_config.base).nil?
    end

    def set_globalized_slug(normalized_slug = nil)
      ::Globalize.with_locale(::Globalize.locale) do
        if should_generate_new_friendly_id?
          candidates = FriendlyId::Candidates.new(self, normalized_slug || send(friendly_id_config.base))
          slug = slug_generator.generate(candidates) || resolve_friendly_id_conflict(candidates)
          send "#{friendly_id_config.slug_column}=", slug
        end
      end
    end
    private :set_globalized_slug

    # This module adds the `:slug_column`, and `:sequence_separator`, and
    # `:slug_generator_class` configuration options to
    # {FriendlyId::Configuration FriendlyId::Configuration}.
    module Configuration
      attr_writer :slug_column, :sequence_separator
      attr_accessor :slug_generator_class

      # Makes FriendlyId use the slug column for querying.
      # @return String The slug column.
      def query_field
        slug_column
      end

      # The string used to separate a slug base from a numeric sequence.
      #
      # You can change the default separator by setting the
      # {FriendlyId::Slugged::Configuration#sequence_separator
      # sequence_separator} configuration option.
      # @return String The sequence separator string. Defaults to "`-`".
      def sequence_separator
        @sequence_separator or defaults[:sequence_separator]
      end

      # The column that will be used to store the generated slug.
      def slug_column
        @slug_column or defaults[:slug_column]
      end
    end
  end
end
