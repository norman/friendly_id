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
      model_class.instance_eval do
        friendly_id_config.use :slugged
        relation_class.send :include, FinderMethods
        include Model
        # Check if slug field is enabled to be translated with Globalize
        unless respond_to?('translated_attribute_names') || translated_attribute_names.exclude?(friendly_id_config.query_field.to_sym)
          puts "\n[FriendlyId] You need to translate '#{friendly_id_config.query_field}' field with Globalize (add 'translates :#{friendly_id_config.query_field}' in your model '#{self.class.name}')\n\n"
        end
      end
    end

    module Model
      def set_friendly_id(text, locale)
        I18n.with_locale(locale || I18n.locale) do
          set_slug(normalize_friendly_id(text))
        end
      end
    end

    module FinderMethods
      # FriendlyId overrides this method to make it possible to use friendly id's
      # identically to numeric ids in finders.
      #
      # @example
      #  person = Person.find(123)
      #  person = Person.find("joe")
      #
      # @see FriendlyId::ObjectUtils
      def find_one(id)
        return super if id.unfriendly_id?
        found = where(@klass.friendly_id_config.query_field => id).first
        found = includes(:translations).
                where(translation_class.arel_table[:locale].in([I18n.locale, I18n.default_locale])).
                where(translation_class.arel_table[@klass.friendly_id_config.query_field].eq(id)).
                references(translation_class.arel_table).first if found.nil?

        if found
          # Reload the translations for the found records.
          found.tap { |f| f.translations.reload }
        else
          # if locale is not translated fallback to default locale
          super
        end
      end

      protected :find_one

    end
  end
end
