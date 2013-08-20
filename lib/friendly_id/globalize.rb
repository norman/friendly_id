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

    class << self

      def setup(model_class)
        model_class.friendly_id_config.use :slugged
      end

      def included(model_class)
        advise_against_untranslated_model(model_class)
      end

      def advise_against_untranslated_model(model)
        field = model.friendly_id_config.query_field
        unless model.respond_to?('translated_attribute_names') ||
               model.translated_attribute_names.exclude?(field.to_sym)
          raise "[FriendlyId] You need to translate the '#{field}' field with " \
            "Globalize (add 'translates :#{field}' in your model '#{model.name}')"
        end
      end
      private :advise_against_untranslated_model
    end

    def set_friendly_id(text, locale = nil)
      ::Globalize.with_locale(locale || ::Globalize.locale) do
        set_slug normalize_friendly_id(text)
      end
    end

    def should_generate_new_friendly_id?
      translation_for(::Globalize.locale).send(friendly_id_config.slug_column).nil?
    end

    def set_slug(normalized_slug = nil)
      ::Globalize.with_locale(::Globalize.locale) { super }
    end
  end
end
