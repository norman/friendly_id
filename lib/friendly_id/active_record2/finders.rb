module FriendlyId

  # The adapter for Ruby on Rails's ActiveRecord. Compatible with AR 2.2.x -
  # 2.3.x.
  module ActiveRecord2

    # The classes in this module are used internally by FriendlyId, and exist
    # largely to avoid polluting the ActiveRecord models with too many
    # FriendlyId-specific methods.
    module Finders

      # FinderProxy is used to choose which {Finder} subclass to instantiate;
      # depending on the model_class's +friendly_id_config+ and the options
      # passed into the constructor, it will decide whether to use simple or
      # slugged finder, a single or multiple finder, and in the case of slugs,
      # a cached or uncached finder.
      class FinderProxy

        attr_reader :finder
        attr :finder_class
        attr :ids
        attr :model_class
        attr :options

        def initialize(ids, model_class, options={})
          @ids = ids
          @model_class = model_class
          @options = options
        end

        def method_missing(symbol, *args)
          finder.send(symbol, *args)
        end

        # Perform the find query.
        def finder
          @finder ||= finder_class.new(ids, model_class, options)
        end

        private

        def finder_class
          @finder_class ||= slugged? ? slugged_finder_class : simple_finder_class
        end

        private

        def cache_available?
          !! model_class.friendly_id_config.cache_column
        end

        def multiple?
          ids.kind_of? Array
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

      # The base finder.
      # @abstract
      class Finder

        extend Forwardable

        %w[all base_class find_every find_initial friendly_id_config primary_key
           quoted_table_name sanitize_sql table_name with_scope].each do |method|
          def_delegator :model_class, method
        end

        # An array of ids; can be both friendly and unfriendly.
        attr_accessor :ids

        # The ActiveRecord query options
        attr_accessor :options

        # The FriendlyId scope
        attr_accessor :scope

        # The model class being used to perform the query.
        attr_accessor :model_class

        class << self

          # Is the id friendly or numeric? Not that the return value here is
          # +false+ if the +id+ is definitely not friendly, and +nil+ if it can
          # not be determined.
          # The return value will be:
          # * +true+ - if the id is definitely friendly (i.e., any string with non-numeric characters)
          # * +false+ - if the id is definitely unfriendly (i.e., an Integer, ActiveRecord::Base, etc.)
          # * +nil+ - if it can not be determined (i.e., a numeric string like "206".)
          # @return [true, false, nil]
          # @see #unfriendly?
          def friendly?(id)
            if id.is_a?(Integer) || id.kind_of?(::ActiveRecord::Base)
              return false
            elsif id.to_i.to_s != id.to_s
              return true
            else
              return nil
            end
          end

          # Is the id numeric?
          # @return [true, false, nil] +true+ if definitely unfriendly, +false+ if
          #   definitely friendly, else +nil+.
          # @see #friendly?
          def unfriendly?(id)
            !friendly?(id) unless friendly?(id) == nil
          end

        end

        def initialize(ids, model_class, options={})
          self.ids = ids
          self.options = options
          self.model_class = model_class
          self.scope = options[:scope]
        end

        # Perform the find.
        def find
          raise NotImplementedError
        end

        private

        def ids=(ids)
          @ids = [ids].flatten
        end
        alias :id= :ids=

        def scope=(scope)
          @scope = scope.to_param unless scope.nil?
        end

        # Whether :include => :slugs has been passed as an option.
        def slugs_included?
          [*(options[:include] or [])].flatten.include?(:slugs)
        end

      end

      # Wraps finds for a single record using a friendly_id.
      class SingleFinder < Finder

        # Is the id definitely friendly?
        # @see Finder::friendly?
        def friendly?
          self.class.friendly?(id)
        end

        # Is the id definitely unfriendly?
        # @see Finder::unfriendly?
        def unfriendly?
          self.class.unfriendly?(id)
        end

        private

        # The id (numeric or friendly).
        def id
          ids[0]
        end

        # The slug name; i.e. if "my-title--2", then "my-title".
        def name
          id.to_s.parse_friendly_id(friendly_id_config.sequence_separator)[0]
        end

        # The slug sequence; i.e. if "my-title--2", then "2".
        def sequence
          id.to_s.parse_friendly_id(friendly_id_config.sequence_separator)[1]
        end

      end

      # Wraps finds for multiple records using an array of friendly_ids.
      class MultipleFinder < Finder

        attr_reader :friendly_ids, :results, :unfriendly_ids

        def initialize(ids, model_class, options={})
          @friendly_ids, @unfriendly_ids = ids.partition {|id| self.class.friendly?(id) }
          @unfriendly_ids = @unfriendly_ids.map {|id| id.kind_of?(ActiveRecord::Base) ? id.id : id}
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
  end
end
