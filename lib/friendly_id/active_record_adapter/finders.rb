module ActiveRecord
  class Base
    class << self
      VALID_FIND_OPTIONS << :scope
    end
  end
end

module FriendlyId
  module ActiveRecordAdapter
    module Finders

      class Find

        attr :klass
        attr :id
        attr :options
        attr :fid_scope

        def method_missing(symbol, *args, &block)
          klass.__send__(symbol, *args, &block)
        end

        def initialize(klass, id, options)
          @klass   = klass
          @id      = id
          @options = options
          @fid_scope   = options.delete(:scope)
          @fid_scope   = @fid_scope.to_param if @fid_scope && @fid_scope.respond_to?(:to_param)
        end

        def find_one
          fc = klass.friendly_id_config
          return find_one_using_cached_slug if fc.cache_column?
          return find_one_using_slug if fc.use_slugs?
          record = scoped(:conditions => ["#{table_name}.#{fc.column} = ?", id]).first(options)
          if record
            record.friendly_id_status.name = name
            record
          end
        end

        def find_one_using_cached_slug
          fc = klass.friendly_id_config
          record = scoped(:conditions => ["#{table_name}.#{fc.cache_column} = ?", id]).first(options)
          if record
            name, seq = id.to_s.parse_friendly_id
            record.friendly_id_status.name = name
            record.friendly_id_status.sequence = seq
            record
          else
            find_one_using_slug
          end
        end

        def find_one_using_slug
          name, seq = id.to_s.parse_friendly_id
          slugs = Slug.table_name.to_sym
          scope = klass.scoped(:conditions => {slugs => {:name => name, :sequence => seq}}, :joins => slugs)
          scope = scope.scoped(:conditions => {slugs => {:scope => fid_scope}}) if friendly_id_config.scope?
          record = scope.first(options)
          return if !record
          record.friendly_id_status.name = name
          record.friendly_id_status.sequence = seq
          record
        end

        def find_some
          @id = id.uniq.map {|i| i.respond_to?(:friendly_id_config) ? i.id.to_i : i}
          friendly_ids, unfriendly_ids = id.partition {|i| i.friendly_id?}
          scope = klass.scoped(:conditions => friendly_conditions(friendly_ids, unfriendly_ids))
          if friendly_id_config.use_slugs? && friendly_ids.present?
            scope = scope.scoped(:joins => Slug.table_name.to_sym)
            if friendly_id_config.scope?
              scope = scope.scoped(:conditions => {:slugs => {:scope => fid_scope}})
            end
          end
          records = scope.all(options).uniq
          expected = expected_size
          if records.size == expected
            records.each { |record| record.friendly_id_status.name = id }
          else
            message = "Couldn't find all %s with IDs (%s) AND %s (found %d results, but was looking for %d)" % [
              name.pluralize,
              id.join(', '),
              sanitize_sql(options[:conditions]),
              records.size,
              expected
            ]
            raise ActiveRecord::RecordNotFound, message
          end
        end

        def raise_error(error)
          raise(error) unless friendly_id_config.scope?
          scope_message = fid_scope || "expected, but none given"
          message = "%s, scope: %s" % [error.message, scope_message]
          raise ::ActiveRecord::RecordNotFound, message
        end

        private

        def expected_size
          if options[:limit] && id.size > options[:limit]
            options[:limit]
          else
            id.size
          end
        end

        def friendly_conditions(friendly_ids, unfriendly_ids)
          fc        = klass.friendly_id_config
          use_slugs = fc.use_slugs? && !fc.cache_column?
          pkey      = "#{quoted_table_name}.#{primary_key}"
          column    = "#{table_name}.#{fc.cache_column || fc.column}"
          if unfriendly_ids.present?
            conditions = ["#{pkey} IN (?)", unfriendly_ids]
            if friendly_ids.present?
              if use_slugs
                conditions[0] << " OR #{slugged_conditions(friendly_ids)}"
              else
                conditions[0] << " OR #{column} IN (?)"
                conditions << friendly_ids
              end
            end
            conditions
          elsif friendly_ids.present?
            use_slugs ? slugged_conditions(friendly_ids) : ["#{column} IN (?)", friendly_ids]
          end
        end

        def slugged_conditions(ids)
          return if ids.empty?
          table = Slug.quoted_table_name
          fragment = "(#{table}.name = %s AND #{table}.sequence = %d)"
          conditions = lambda do |id|
            name, seq = id.parse_friendly_id
            fragment % [connection.quote(name), seq]
          end
          ids.inject(nil) {|clause, id| clause ? clause + " OR #{conditions.call(id)}" : conditions.call(id) }
        end
      end

      def find_one(id, options)
        return super if id.blank? || id.unfriendly_id?
        finder = Find.new(self, id, options)
        finder.find_one or super
      rescue ActiveRecord::RecordNotFound => error
        finder.raise_error(error)
      end

      def find_some(ids, options)
        return super if ids.empty?
        finder = Find.new(self, ids, options)
        finder.find_some
      rescue ActiveRecord::RecordNotFound => error
        finder.raise_error(error)
      end
    end
  end
end