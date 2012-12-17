require "friendly_id/slugged"

module FriendlyId

=begin

== Unique Slugs by Scope

The {FriendlyId::Scoped} module allows FriendlyId to generate unique slugs
within a scope.

This allows, for example, two restaurants in different cities to have the slug
+joes-diner+:

    class Restaurant < ActiveRecord::Base
      extend FriendlyId
      belongs_to :city
      friendly_id :name, :use => :scoped, :scope => :city
    end

    class City < ActiveRecord::Base
      extend FriendlyId
      has_many :restaurants
      friendly_id :name, :use => :slugged
    end

    City.find("seattle").restaurants.find("joes-diner")
    City.find("chicago").restaurants.find("joes-diner")

Without :scoped in this case, one of the restaurants would have the slug
+joes-diner+ and the other would have +joes-diner--2+.

The value for the +:scope+ option can be the name of a +belongs_to+ relation, or
a column.

Additionally, the +:scope+ option can receive an array of scope values:

    class Cuisine < ActiveRecord::Base
      extend FriendlyId
      has_many :restaurants
      friendly_id :name, :use => :slugged
    end

    class City < ActiveRecord::Base
      extend FriendlyId
      has_many :restaurants
      friendly_id :name, :use => :slugged
    end

    class Restaurant < ActiveRecord::Base
      extend FriendlyId
      belongs_to :city
      friendly_id :name, :use => :scoped, :scope => [:city, :cuisine]
    end

All supplied values will be used to determine scope.

=== Finding Records by Friendly ID

If you are using scopes your friendly ids may not be unique, so a simple find
like

    Restaurant.find("joes-diner")

may return the wrong record. In these cases it's best to query through the
relation:

    @city.restaurants.find("joes-diner")

Alternatively, you could pass the scope value as a query parameter:

    Restaurant.find("joes-diner").where(:city_id => @city.id)


=== Finding All Records That Match a Scoped ID

Query the slug column directly:

    Restaurant.find_all_by_slug("joes-diner")

=== Routes for Scoped Models

Recall that FriendlyId is a database-centric library, and does not set up any
routes for scoped models. You must do this yourself in your application. Here's
an example of one way to set this up:

    # in routes.rb
    resources :cities do
      resources :restaurants
    end

    # in views
    <%= link_to 'Show', [@city, @restaurant] %>

    # in controllers
    @city = City.find(params[:city_id])
    @restaurant = @city.restaurants.find(params[:id])

    # URLs:
    http://example.org/cities/seattle/restaurants/joes-diner
    http://example.org/cities/chicago/restaurants/joes-diner

=end
  module Scoped


    # Sets up behavior and configuration options for FriendlyId's scoped slugs
    # feature.
    def self.included(model_class)
      model_class.instance_eval do
        raise "FriendlyId::Scoped is incompatibe with FriendlyId::History" if self < History
        include Slugged unless self < Slugged
        friendly_id_config.class.send :include, Configuration
        friendly_id_config.slug_generator_class.send :include, SlugGenerator
      end
    end

    # This module adds the +:scope+ configuration option to
    # {FriendlyId::Configuration FriendlyId::Configuration}.
    module Configuration

      # Gets the scope value.
      #
      # When setting this value, the argument should be a symbol referencing a
      # +belongs_to+ relation, or a column.
      #
      # @return Symbol The scope value
      attr_accessor :scope

      # Gets the scope columns.
      #
      # Checks to see if the +:scope+ option passed to
      # {FriendlyId::Base#friendly_id} refers to a relation, and if so, returns
      # the realtion's foreign key. Otherwise it assumes the option value was
      # the name of column and returns it cast to a String.
      #
      # @return String The scope column
      def scope_columns
        [@scope].flatten.map { |s| (reflection_foreign_key(s) or s).to_s }
      end

      private

      if ActiveRecord::VERSION::STRING < "3.1"
        def reflection_foreign_key(scope)
          model_class.reflections[scope].try(:primary_key_name)
        end
      else
        def reflection_foreign_key(scope)
          model_class.reflections[scope].try(:foreign_key)
        end
      end
    end

    # This module overrides {FriendlyId::SlugGenerator#conflict} to consider
    # scope, to avoid adding sequences to slugs under different scopes.
    module SlugGenerator

      private

      def conflict
        columns = friendly_id_config.scope_columns
        matched = columns.inject(conflicts) do |memo, column|
           memo.where(column => sluggable.send(column))
        end

        matched.first
      end
    end
  end
end
