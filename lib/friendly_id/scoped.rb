require "friendly_id/slugged"

module FriendlyId

=begin
This module allows FriendlyId to generate unique slugs within a scope.

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

== Tips For Working With Scoped Slugs

=== Finding Records by Friendly ID

If you are using scopes your friendly ids may not be unique, so a simple find
like

    Restaurant.find("joes-diner")

may return the wrong record. In these cases it's best to query through the
relation:

    @city.restaurants.find("joes-diner")

Alternatively, you could pass the scope value as a parameter:

    Restaurant.find("joes-diner").where(:city_id => @city.id)


=== Finding All Records That Match a Scoped ID

Query the slug column directly:

    Restaurant.find_all_by_slug("joes-diner")

=== Routes for Scoped Models

FriendlyId does not set up any routes for scoped models; you must do this
yourself in your application. Here's an example of one way to set this up:

    # in routes.rb
    resources :cities do
      resources :restaurants
    end

    # in views
    <%= link_to 'Show', [@city, @restaurant] %>

    # in controllers
    @city = City.find(params[:city_id])
    @restaurant = @city.restaurants.find(params[:id])

    # URL's:
    http://example.org/cities/seattle/restaurants/joes-diner
    http://example.org/cities/chicago/restaurants/joes-diner

=end
  module Scoped
    def self.included(model_class)
      model_class.instance_eval do
        raise "FriendlyId::Scoped is incompatibe with FriendlyId::History" if self < History
        include Slugged unless self < Slugged
        friendly_id_config.class.send :include, Configuration
        friendly_id_config.slug_sequencer_class.send :include, SlugSequencer
      end
    end

    module Configuration
      attr_accessor :scope

      # Gets the scope column.
      #
      # Checks to see if the +:scope+ option passed to {#friendly_id}
      # refers to a relation, and if so, returns the realtion's foreign key.
      # Otherwise it assumes the option value was the name of column and returns
      # it cast to a String.
      # @return String The scope column
      def scope_column
        (model_class.reflections[@scope].try(:association_foreign_key) || @scope).to_s
      end
    end

    module SlugSequencer
      def conflict
        column = friendly_id_config.scope_column
        conflicts.where("#{column} = ?", sluggable.send(column)).first
      end
    end
  end
end
