module FriendlyId
  module ActiveRecordAdapter
    module Finders

      class Find
        extend Forwardable
        def_delegators :@klass, :scoped, :friendly_id_config, :quoted_table_name, :table_name, :primary_key,
          :connection, :name, :sanitize_sql
        def_delegators :fc, :use_slugs?, :cache_column, :cache_column?
        alias fc friendly_id_config

        attr :klass
        attr :id
        attr :options
        attr :scope_val
        attr :result
        attr :friendly_ids
        attr :unfriendly_ids

        def initialize(klass, id, options)
          @klass     = klass
          @id        = id
          @options   = options
          @scope_val = options.delete(:scope)
          @scope_val = @scope_val.to_param if @scope_val && @scope_val.respond_to?(:to_param)
        end

        def find_one
          return find_one_using_cached_slug if cache_column?
          return find_one_using_slug if use_slugs?
          @result = scoped(:conditions => ["#{table_name}.#{fc.column} = ?", id]).first(options)
          assign_status
        end

        def find_some
          parse_ids!
          scope = some_friendly_scope
          if use_slugs? && @friendly_ids.present?
            scope = scope.scoped(:joins => :slugs)
            if fc.scope?
              scope = scope.scoped(:conditions => {:slugs => {:scope => scope_val}})
            end
          end
          options[:readonly] = false unless options[:readonly]
          @result = scope.all(options).uniq
          validate_expected_size!
          @result.each { |record| record.friendly_id_status.name = id }
        end

        def raise_error(error)
          raise(error) unless fc.scope?
          scope_message = scope_val || "expected, but none given"
          message = "%s, scope: %s" % [error.message, scope_message]
          raise ActiveRecord::RecordNotFound, message
        end

        private

        def find_one_using_cached_slug
          @result = scoped(:conditions => ["#{table_name}.#{cache_column} = ?", id]).first(options)
          assign_status or find_one_using_slug
        end

        def find_one_using_slug
          name, seq = id.to_s.parse_friendly_id
          scope = scoped(:joins => :slugs, :conditions => {:slugs => {:name => name, :sequence => seq}})
          scope = scope.scoped(:conditions => {:slugs => {:scope => scope_val}}) if fc.scope?
          options[:readonly] = false unless options[:readonly]
          @result = scope.first(options)
          assign_status
        end

        def parse_ids!
          @id = id.uniq.map do |member|
            if member.respond_to?(:friendly_id_config)
              member.id.to_i
            else
              member
            end
          end
          @friendly_ids, @unfriendly_ids = @id.partition {|member| member.friendly_id?}
        end

        def validate_expected_size!
          expected = expected_size
          return if @result.size == expected
          message = "Couldn't find all %s with IDs (%s) AND %s (found %d results, but was looking for %d)" % [
            name.pluralize,
            id.join(', '),
            sanitize_sql(options[:conditions]),
            result.size,
            expected
          ]
          raise ActiveRecord::RecordNotFound, message
        end

        def assign_status
          return unless @result
          name, seq = @id.to_s.parse_friendly_id
          @result.friendly_id_status.name = name
          @result.friendly_id_status.sequence = seq if use_slugs?
          @result
        end

        def expected_size
          if options[:limit] && @id.size > options[:limit]
            options[:limit]
          else
            @id.size
          end
        end

        def some_friendly_scope
          query_slugs = use_slugs? && !cache_column?
          pkey      = "#{quoted_table_name}.#{primary_key}"
          column    = "#{table_name}.#{cache_column || fc.column}"
          if @unfriendly_ids.present?
            conditions = ["#{pkey} IN (?)", @unfriendly_ids]
            if @friendly_ids.present?
              if query_slugs
                conditions[0] << " OR #{some_slugged_conditions}"
              else
                conditions[0] << " OR #{column} IN (?)"
                conditions << @friendly_ids
              end
            end
          elsif @friendly_ids.present?
            conditions = query_slugs ? some_slugged_conditions : ["#{column} IN (?)", @friendly_ids]
          end
          scoped(:conditions => conditions)
        end

        def some_slugged_conditions
          return unless @friendly_ids.present?
          slug_table = Slug.quoted_table_name
          fragment = "(#{slug_table}.name = %s AND #{slug_table}.sequence = %d)"
          @friendly_ids.inject(nil) do |clause, id|
            name, seq = id.parse_friendly_id
            string = fragment % [connection.quote(name), seq]
            clause ? clause + " OR #{string}" : string
          end
        end
      end

      def find_one(id, options)
        return super if id.blank? || id.unfriendly_id?
        finder = Find.new(self, id, options)
        finder.find_one or super
      rescue ActiveRecord::RecordNotFound => error
        finder ? finder.raise_error(error) : raise(error)
      end

      def find_some(ids, options)
        return super if ids.empty?
        finder = Find.new(self, ids, options)
        finder.find_some
      rescue ActiveRecord::RecordNotFound => error
        finder ? finder.raise_error(error) : raise(error)
      end
    end
  end
end
