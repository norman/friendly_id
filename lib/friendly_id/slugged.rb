require "friendly_id/slug_sequencer"

module FriendlyId

  # This module adds in-table slugs to an ActiveRecord model.
  module Slugged

    def self.included(klass)
      klass.instance_eval do
        friendly_id_config.class.send :include, Configuration
        friendly_id_config.defaults[:slug_column]        = 'slug'
        friendly_id_config.defaults[:sequence_separator] = '--'
        friendly_id_config.slug_sequencer_class          = Class.new(SlugSequencer)
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
