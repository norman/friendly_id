module FriendlyId

  # The adapter for Ruby on Rails's ActiveRecord. Compatible with AR 2.2.x -
  # 2.3.x.
  module ActiveRecordAdapter

    # The classes in this module are used internally by FriendlyId, and exist
    # largely to avoid polluting the ActiveRecord models with too many
    # FriendlyId-specific methods.
    module Finders

      # FinderProxy is used to choose which finder class to instantiate;
      # depending on the model_class's +friendly_id_config+ and the options
      # passed into the constructor, it will decide whether to use simple or
      # slugged finder, a single or multiple finder, and in the case of slugs,
      # a cached or uncached finder.
      class FinderProxy

        extend Forwardable

        attr_reader :finder
        attr :finder_class
        attr :ids
        attr :model_class
        attr :options

        def_delegators :finder, :find, :unfriendly?

        def initialize(model_class, *args, &block)
          @model_class = model_class
          @ids = args.shift
          @options = args.first.kind_of?(Hash) ? args.first : {}
        end

        # Perform the find query.
        def finder
          @finder ||= finder_class.new(ids, model_class, options)
        end

        def finder_class
          @finder_class ||= slugged? ? slugged_finder_class : simple_finder_class
        end

        def multiple?
          ids.kind_of? Array
        end

        private

        def cache_available?
          !! model_class.friendly_id_config.cache_column
        end

        def multiple_slugged_finder_class
          use_cache? ? SluggedModel::CachedMultipleFinder : SluggedModel::MultipleFinder
        end

        def simple_finder_class
          multiple? ? SimpleModel::MultipleFinder : SimpleModel::SingleFinder
        end

        def slugged?
          !! model_class.friendly_id_config.use_slug?
        end

        def slugged_finder_class
          multiple? ? multiple_slugged_finder_class : single_slugged_finder_class
        end

        def scoped?
          !! options[:scope]
        end

        def single_slugged_finder_class
          use_cache? ? SluggedModel::CachedSingleFinder : SluggedModel::SingleFinder
        end

        def use_cache?
          cache_available? and !scoped?
        end

      end

      # Wraps finds for multiple records using an array of friendly_ids.
      # @abstract
      module Multiple

        include FriendlyId::Finders::Base

        attr_reader :friendly_ids, :results, :unfriendly_ids

        def initialize(ids, model_class, options={})
          @friendly_ids, @unfriendly_ids = ids.partition {|id| FriendlyId::Finders::Base.friendly?(id) }
          @unfriendly_ids = @unfriendly_ids.map {|id| id.class.respond_to?(:friendly_id_config) ? id.id : id}
          super
        end

        private

        # An error message to use when the wrong number of results was returned.
        def error_message
          "Couldn't find all %s with IDs (%s) AND %s (found %d results, but was looking for %d)" % [
            model_class.name.pluralize,
            ids.join(', '),
            sanitize_sql(options[:conditions]),
            results.size,
            expected_size
          ]
        end

        # How many results do we expect?
        def expected_size
          limited? ? limit : offset_size
        end

        # The limit option passed to the find.
        def limit
          options[:limit]
        end

        # Is the find limited?
        def limited?
          offset_size > limit if limit
        end

        # The offset used for the find. If no offset was passed, 0 is returned.
        def offset
          options[:offset].to_i
        end

        # The number of ids, minus the offset.
        def offset_size
          ids.size - offset
        end

      end

    end

    # The methods in this module override ActiveRecord's +find_one+ and
    # +find_some+ to add FriendlyId's features.
    module FinderMethods

      def find(*args, &block)
        finder = Finders::FinderProxy.new(self, *args, &block)
        if finder.multiple?
          finder.find
        else
          finder.unfriendly? ? super : finder.find or super
        end
      end

    end

  end
end
