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
        records = friendly_records(*ids.partition {|id| id.friendly_id?}).each do |record|
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
        use_slugs  = friendly_id_config.use_slugs? && !friendly_id_config.cache_column?
        column     = friendly_id_config.cache_column || friendly_id_config.column
        friendly   = use_slugs ? slugged_conditions(friendly_ids) : arel_table[column].in(friendly_ids)
        unfriendly = arel_table[primary_key].in unfriendly_ids
        if friendly_ids.present? && unfriendly_ids.present?
          clause = friendly.or(unfriendly)
        elsif friendly_ids.present?
          clause = friendly
        elsif unfriendly_ids.present?
          clause = unfriendly
        end
        use_slugs ? includes(:slugs).where(clause) : where(clause)
      end

      def slugged_conditions(ids)
        return if ids.empty?
        slugs = Slug.arel_table
        conditions = lambda do |id|
          name, seq = id.parse_friendly_id
          slugs[:name].eq(name).and(slugs[:sequence].eq(seq)).and(slugs[:scope].eq(friendly_id_scope))
        end
        ids.inject(nil) {|clause, id| clause ? clause.or(conditions.call(id)) : conditions.call(id) }
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
