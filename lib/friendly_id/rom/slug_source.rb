module FriendlyId
  module Rom
    # Adapts a plain attributes hash to the small interface
    # {FriendlyId::Candidates} expects of a record.
    #
    # Active Record hands `Candidates` a model instance, which answers both
    # `friendly_id_config` and the attribute methods a candidate refers to. ROM
    # has no such object at write time, only a hash, so this stands in for one.
    class SlugSource
      def initialize(config, attributes)
        @config = config
        # Normalize keys so that both :title and "title" resolve.
        @attributes = attributes.each_with_object({}) { |(k, v), h| h[k.to_sym] = v }
      end

      attr_reader :attributes

      def friendly_id_config
        @config
      end

      # Overridable in the same spirit as the Active Record adapter's
      # `normalize_friendly_id`, but resolved through the configured normalizer
      # since there is no model class to override.
      #
      # The normalizer is called without a `separator:`, so it uses its own
      # default of "-". `sequence_separator` is deliberately not passed: it
      # separates a slug from its numeric sequence, not the words within a slug.
      # Both adapters must agree here, or the same title and configuration would
      # give "hello-world:2" on Active Record and "hello:world:2" on ROM.
      def normalize_friendly_id(value)
        slug = @config.normalizer.call(value)
        slug = slug[0...@config.slug_limit] if @config.slug_limit
        slug
      end

      def respond_to_missing?(name, include_private = false)
        @attributes.key?(name.to_sym) || super
      end

      def method_missing(name, *args)
        return super unless @attributes.key?(name.to_sym)

        @attributes[name.to_sym]
      end
    end
  end
end
