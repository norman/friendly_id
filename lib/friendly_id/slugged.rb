# encoding: utf-8
require "friendly_id/slug_sequencer"

module FriendlyId
=begin
This module adds in-table slugs to a model.

Slugs are strings that have been processed to remove or replace characters that
a developer considers inconvenient for use in URLs. For example, blog
applications typically use a post title to provide the basis of a search engine
friendly URL:

    "Gone With The Wind" -> "gone-with-the-wind"

FriendlyId generates slugs from a method or column that you specify, and stores
them in a field in your model. By default, this field must be named +:slug+,
though you may change this using the
{FriendlyId::Slugged::Configuration#slug_column slug_column} configuration
option. You should add an index to this field. You may also wish to constrain it
to NOT NULL, but this is optional.

=== Example Setup

    # your model
    class Post < ActiveRecord::Base
      extend FriendlyId
      friendly_id :title, :use => :slugged
      validates_presence_of :title, :slug, :body
    end

    # a migration
    class CreatePosts < ActiveRecord::Migration
      def self.up
        create_table :posts do |t|
          t.string :title, :null => false
          t.string :slug, :null => false
          t.text :body
        end

        add_index :posts, :slug, :unique => true
      end

      def self.down
        drop_table :posts
      end
    end

=== Slug Format

By default, FriendlyId uses Active Support's
paramaterize[http://api.rubyonrails.org/classes/ActiveSupport/Inflector.html#method-i-parameterize]
method to create slugs. This method will take care of intelligently replacing
spaces with dashes, and replacing characters from Unicode Latin characters with
ASCII approximations:

  movie = Movie.create! :title => "Der Preis fürs Überleben"
  movie.slug #=> "der-preis-furs-uberleben"

==== Slug Uniqueness

WRITE ME

==== Changing the Slug Sequence Separator

WRITE ME

==== Column or Method?

WRITE ME

==== Providing Your Own Slug Processing Method

WRITE ME

==== Babosa

WRITE ME

==== Locale-specific Transliterations

Active Support's +parameterize+ uses
transliterate[http://api.rubyonrails.org/classes/ActiveSupport/Inflector.html#method-i-transliterate],
which in turn can use I18n's transliteration rules to consider the current
locale when replacing Latin characters:

  # config/locales/de.yml
  de:
    i18n:
      transliterate:
        rule:
          ü: "ue"
          ö: "oe"
          etc...

  movie = Movie.create! :title => "Der Preis fürs Überleben"
  movie.slug #=> "der-preis-fuers-ueberleben"

This functionality was in fact taken from earlier versions of FriendlyId.
=end
  module Slugged

    def self.included(model_class)
      model_class.instance_eval do
        friendly_id_config.class.send :include, Configuration
        friendly_id_config.defaults[:slug_column]        ||= 'slug'
        friendly_id_config.defaults[:sequence_separator] ||= '--'
        friendly_id_config.slug_sequencer_class          ||= Class.new(SlugSequencer)
        before_validation :set_slug
      end
    end

    def normalize_friendly_id(value)
      value.to_s.parameterize
    end

    def slug_sequencer
      friendly_id_config.slug_sequencer_class.new(self)
    end

    private

    def set_slug
      send "#{friendly_id_config.slug_column}=", slug_sequencer.generate
    end

    module Configuration
      attr_writer :slug_column, :sequence_separator
      attr_accessor :slug_sequencer_class

      def query_field
        slug_column
      end

      def sequence_separator
        @sequence_separator or defaults[:sequence_separator]
      end

      def slug_column
        @slug_column or defaults[:slug_column]
      end
    end
  end
end
