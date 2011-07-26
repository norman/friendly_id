require "friendly_id/slugged"

module FriendlyId

  # This module adds scopes to in-table slugs. It's not loaded by default,
  # so in order to active this feature you must include the module in your
  # class.
  #
  # You can scope by an explicit column, or by a `belongs_to` relation.
  #
  # @example
  #   class Restaurant < ActiveRecord::Base
  #     belongs_to :city
  #     include FriendlyId::Scoped
  #     friendly_id :name, :scope => :city
  #   end
  module Scoped
    def self.included(klass)
      klass.instance_eval do
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
        (klass.reflections[@scope].try(:association_foreign_key) || @scope).to_s
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
