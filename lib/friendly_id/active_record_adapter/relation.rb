module FriendlyId
  module ActiveRecordAdapter
    module Relation

      attr :friendly_id_scope

      # This method overrides Active Record's default in order to allow the :scope option to
      # be passed to finds.
      def apply_finder_options(options)
        @friendly_id_scope = options.delete(:scope)
        @friendly_id_scope = @friendly_id_scope.to_param if @friendly_id_scope.respond_to?(:to_param)
        super
      end

      protected

      def find_one(id)
        begin
          return super if !@klass.uses_friendly_id? or id.unfriendly_id?
          return find_one_using_cached_slug(id) if friendly_id_config.cache_column?
          return find_one_using_slug(id) if friendly_id_config.use_slugs?
          record = where(friendly_id_config.column => id).first
          if record
            record.friendly_id_status.name = name
            record
          else
            super
          end
        rescue ActiveRecord::RecordNotFound => error
          uses_friendly_id? && friendly_id_config.scope? ? raise_scoped_error(error) : raise(error)
        end
      end

      def find_some(ids)
        return super unless @klass.uses_friendly_id?
        ids = ids.compact.uniq.map {|id| id.respond_to?(:friendly_id_config) ? id.id.to_i : id}
        friendly_ids, unfriendly_ids = ids.partition {|id| id.friendly_id?}
        return super if friendly_ids.empty?
        records = friendly_records(friendly_ids, unfriendly_ids).each do |record|
          record.friendly_id_status.name = ids
        end
        validate_expected_size!(ids, records)
      end

      private

      def find_one_using_slug(id)
        name, seq = id.to_s.parse_friendly_id
        slug = Slug.where(:name => name, :sequence => seq, :scope => friendly_id_scope,
                          :sluggable_type => @klass.base_class.to_s).first
        if slug
          record = find_one(slug.sluggable_id.to_i)
          record.friendly_id_status.name = name
          record.friendly_id_status.sequence = seq
          record.friendly_id_status.slug = slug
          record
        else
          find_one_without_friendly(id)
        end
      end

      def find_one_using_cached_slug(id)
        record = where(friendly_id_config.cache_column => id).first
        if record
          name, seq = id.to_s.parse_friendly_id
          record.friendly_id_status.name = name
          record.friendly_id_status.sequence = seq
          record
        else
          find_one_using_slug(id)
        end
      end

      def raise_scoped_error(error)
        scope_message = friendly_id_scope || "expected, but none given"
        message = "%s, scope: %s" % [error.message, scope_message]
        raise ActiveRecord::RecordNotFound, message
      end

      def friendly_records(friendly_ids, unfriendly_ids)
        return find_some_using_slug(friendly_ids, unfriendly_ids) if should_use_slugs?
        column     = friendly_id_config.cache_column || friendly_id_config.column
        friendly   = arel_table[column].in(friendly_ids)
        unfriendly = arel_table[primary_key].in unfriendly_ids
        if friendly_ids.present? && unfriendly_ids.present?
          where(friendly.or(unfriendly))
        else
          where(friendly)
        end
      end

      def should_use_slugs?
        friendly_id_config.use_slugs? && (friendly_id_scope || !friendly_id_config.cache_column?)
      end

      def find_some_using_slug(friendly_ids, unfriendly_ids)
        ids = [unfriendly_ids + sluggable_ids_for(friendly_ids)].flatten.uniq
        where(arel_table[primary_key].in(ids))
      end

      def sluggable_ids_for(ids)
        return [] unless ids.present?
        fragment = "(slugs.name = %s AND slugs.sequence = %d)"
        conditions = ids.inject(nil) do |clause, id|
          name, seq = id.parse_friendly_id
          string = fragment % [connection.quote(name), seq]
          clause ? clause + " OR #{string}" : string
        end
        if friendly_id_scope
          scope = connection.quote(friendly_id_scope)
          conditions = "slugs.scope = %s AND (%s)" % [scope, conditions]
        end
        sql = "SELECT sluggable_id FROM slugs WHERE (%s)" % conditions
        connection.execute(sql).map {|r| r[0]}
      end

      def validate_expected_size!(ids, result)
        expected_size =
          if @limit_value && ids.size > @limit_value
            @limit_value
          else
            ids.size
          end

        # 11 ids with limit 3, offset 9 should give 2 results.
        if @offset_value && (ids.size - @offset_value < expected_size)
          expected_size = ids.size - @offset_value
        end

        if result.size == expected_size
          result
        else
          conditions = arel.send(:where_clauses).join(', ')
          conditions = " [WHERE #{conditions}]" if conditions.present?

          error = "Couldn't find all #{@klass.name.pluralize} with IDs "
          error << "(#{ids.join(", ")})#{conditions} (found #{result.size} results, but was looking for #{expected_size})"
          raise ActiveRecord::RecordNotFound, error
        end
      end
    end
  end
end
