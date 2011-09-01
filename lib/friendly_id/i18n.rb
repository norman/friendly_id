require "i18n"

module FriendlyId

=begin
This module adds very basic i18n support to FriendlyId.

In order to use this module, your model must have a slug column for each locale.
The slug column for your default locale should, however, still be named "slug".
An i18n module that uses external slugs and doesn't require a column for each
locale is planned, but has not been created yet.

== Example migration

  def self.up
    create_table :posts do |t|
      t.string :title
      t.string :slug
      t.string :slug_es
      t.text   :body
    end
    add_index :posts, :slug
    add_index :posts, :slug_es
  end

== Finds

Finds will take into consideration the current locale:

  I18n.locale = :es
  Post.find("la-guerra-de-las-galaxas")
  I18n.locale = :en
  Post.find("star-wars")

To find a slug by an explicit locale, perform the find inside a block
passed to I18n's +with_locale+ method:

  I18n.with_locale(:es) do
    Post.find("la-guerra-de-las-galaxas")
  end

== Creating Records

When new records are created, the slug is generated for the current locale only.

== Translating Slugs

To translate an existing record's friendly_id, use {#set_friendly_id}. This will
ensure that the slug you add is properly escaped, transliterated and sequenced:

  post = Post.create :name => "Star Wars"
  post.set_friendly_id("La guerra de las galaxas", :es)

If you don't pass in a locale argument, FriendlyId::I18n will just use the
current locale:

  I18n.with_locale(:es) do
    post.set_friendly_id("la-guerra-de-las-galaxas")
  end
=end
  module I18n
    def self.included(model_class)
      model_class.instance_eval do
        friendly_id_config.use :slugged
        friendly_id_config.class.send :include, Configuration
        include Model
      end
    end

    module Model
      def set_friendly_id(text, locale = nil)
        ::I18n.with_locale(locale || ::I18n.current_locale) do
          set_slug(normalize_friendly_id(text))
        end
      end
    end

    module Configuration
      def slug_column
        ::I18n.locale == ::I18n.default_locale ? super : [super, "_", ::I18n.locale].join
      end
    end
  end
end