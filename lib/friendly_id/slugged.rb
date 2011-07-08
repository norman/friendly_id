require "friendly_id/slug_sequencer"

module FriendlyId

  # This module adds in-table slugs to an ActiveRecord model.
  module Slugged

    # @NOTE AR-specific code here
    def self.included(klass)
      klass.before_save :set_slug
      klass.friendly_id_config.use_slugs = true
    end

    # @NOTE AS-specific code here
    def normalize_friendly_id(value)
      value.to_s.parameterize
    end

    def slug_sequencer
      SlugSequencer.new(self)
    end

    private

    def set_slug
      send "#{friendly_id_config.slug_column}=", slug_sequencer.generate
    end
  end

  class Configuration
    attr :use_slugs
    attr_writer :slug_column, :sequence_separator, :use_slugs

    DEFAULTS[:slug_column]        = 'slug'
    DEFAULTS[:sequence_separator] = '--'

    undef query_field

    def query_field
      use_slugs ? slug_column : base
    end

    def sequence_separator
      @sequence_separator ||= DEFAULTS[:sequence_separator]
    end

    def slug_column
      @slug_column ||= DEFAULTS[:slug_column]
    end
  end
end
