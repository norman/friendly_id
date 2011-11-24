# encoding: utf-8
require "friendly_id/slug_generator"

module FriendlyId
=begin
This module adds in-table slugs to a model.

Slugs are unique id strings that have been processed to remove or replace
characters that a developer considers inconvenient for use in URLs. For example,
blog applications typically use a post title to provide the basis of a search
engine friendly URL:

    "Gone With The Wind" -> "gone-with-the-wind"

FriendlyId generates slugs from a method or column that you specify, and stores
them in a field in your model. By default, this field must be named +:slug+,
though you may change this using the
{FriendlyId::Slugged::Configuration#slug_column slug_column} configuration
option. You should add an index to this field. You may also wish to constrain it
to NOT NULL, but this depends on your app's behavior and requirements.

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
method to create slugs. This method will intelligently replace spaces with
dashes, and Unicode Latin characters with ASCII approximations:

  movie = Movie.create! :title => "Der Preis fürs Überleben"
  movie.slug #=> "der-preis-furs-uberleben"

==== Slug Uniqueness

When you try to insert a record that would generate a duplicate friendly id,
FriendlyId will append a sequence to the generated slug to ensure uniqueness:

  car = Car.create :title => "Peugot 206"
  car2 = Car.create :title => "Peugot 206"

  car.friendly_id #=> "peugot-206"
  car2.friendly_id #=> "peugot-206--2"

==== Changing the Slug Sequence Separator

You can do this with the {Slugged::Configuration#sequence_separator
sequence_separator} configuration option.

==== Column or Method?

FriendlyId always uses a method as the basis of the slug text - not a column. It
first glance, this may sound confusing, but remember that Active Record provides
methods for each column in a model's associated table, and that's what
FriendlyId uses.

Here's an example of a class that uses a custom method to generate the slug:

  class Person < ActiveRecord::Base
    friendly_id :name_and_location
    def name_and_location
      "#{name} from #{location}"
    end
  end

  bob = Person.create! :name => "Bob Smith", :location => "New York City"
  bob.friendly_id #=> "bob-smith-from-new-york-city"

==== Providing Your Own Slug Processing Method

You can override {Slugged#normalize_friendly_id} in your model for total
control over the slug format.

==== Deciding when to generate new slugs

Overriding {Slugged#should_generate_new_friendly_id?} lets you control whether
new friendly ids are created when a model is updated. For example, if you only
want to generate slugs once and then treat them as read-only:

  class Post < ActiveRecord::Base
    extend FriendlyId
    friendly_id :title, :use => :slugged

    def should_generate_new_friendly_id?
      new_record?
    end
  end

  post = Post.create!(:title => "Hello world!")
  post.slug #=> "hello-world"
  post.title = "Hello there, world!"
  post.save!
  post.slug #=> "hello-world"

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

    # Sets up behavior and configuration options for FriendlyId's slugging
    # feature.
    def self.included(model_class)
      model_class.instance_eval do
        friendly_id_config.class.send :include, Configuration
        friendly_id_config.defaults[:slug_column]        ||= 'slug'
        friendly_id_config.defaults[:sequence_separator] ||= '--'
        friendly_id_config.slug_generator_class          ||= Class.new(SlugGenerator)
        before_validation :set_slug
      end
    end

    # Process the given value to make it suitable for use as a slug.
    #
    # This method is not intended to be invoked directly; FriendlyId uses it
    # internaly to process strings into slugs.
    #
    # However, if FriendlyId's default slug generation doesn't suite your needs,
    # you can override this method in your model class to control exactly how
    # slugs are generated.
    #
    # === Example
    #
    #   class Person < ActiveRecord::Base
    #     friendly_id :name_and_location
    #
    #     def name_and_location
    #       "#{name} from #{location}"
    #     end
    #
    #     # Use default slug, but upper case and with underscores
    #     def normalize_friendly_id(string)
    #       super.upcase.gsub("-", "_")
    #     end
    #   end
    #
    #   bob = Person.create! :name => "Bob Smith", :location => "New York City"
    #   bob.friendly_id #=> "BOB_SMITH_FROM_NEW_YORK_CITY"
    #
    # === More Resources
    #
    # You might want to look into Babosa[https://github.com/norman/babosa],
    # which is the slugging library used by FriendlyId prior to version 4, which
    # offers some specialized functionality missing from Active Support.
    #
    # @param [#to_s] value The value used as the basis of the slug.
    # @return The candidate slug text, without a sequence.
    def normalize_friendly_id(value)
      value.to_s.parameterize
    end

    # Whether to generate a new slug.
    #
    # You can override this method in your model if, for example, you only want
    # slugs to be generated once, and then never updated.
    def should_generate_new_friendly_id?
      base = send(friendly_id_config.base)
      if base.nil? && slug.nil?
        return false
      elsif new_record?
        return true
      end
      slug_base = normalize_friendly_id(base)
      separator = Regexp.escape friendly_id_config.sequence_separator
      slug_base != current_friendly_id.try(:sub, /#{separator}[\d]*\z/, '')
    end

    # Sets the slug.
    # FIXME: This method sucks and the logic is pretty dubious.
    def set_slug(normalized_slug = nil)
      if normalized_slug || should_generate_new_friendly_id?
        normalized_slug ||= normalize_friendly_id send(friendly_id_config.base)
        generator = friendly_id_config.slug_generator_class.new self, normalized_slug
        send "#{friendly_id_config.slug_column}=", generator.generate
      end
    end
    private :set_slug

    # This module adds the +:slug_column+, and +:sequence_separator+, and
    # +:slug_generator_class+ configuration options to
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
      # By default, +--+ is used to separate the slug from the sequence.
      # FriendlyId uses two dashes to distinguish sequences from slugs with
      # numbers in their name.
      #
      # You can change the default separator by setting the
      # {FriendlyId::Slugged::Configuration#sequence_separator
      # sequence_separator} configuration option.
      #
      # For obvious reasons, you should avoid setting it to "+-+" unless you're
      # sure you will never want to have a friendly id with a number in it.
      # @return String The sequence separator string. Defaults to "+--+".
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
