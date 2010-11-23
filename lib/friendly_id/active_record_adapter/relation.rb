module FriendlyId
  module ActiveRecordAdapter
    module Relation

      class Find
        extend Forwardable

        attr :relation
        attr :ids
        alias id ids

        def_delegators :relation, :arel, :arel_table, :klass, :limit_value, :offset_value, :where
        def_delegators :klass, :connection, :friendly_id_config
        alias fc friendly_id_config

        def initialize(relation, ids)
          @relation = relation
          @ids = ids
        end

        def find_one
          if fc.cache_column?
            find_one_with_cached_slug
          elsif fc.use_slugs?
            find_one_with_slug
          else
            find_one_without_slug
          end
        end

        def find_some
          ids = @ids.compact.uniq.map {|id| id.respond_to?(:friendly_id_config) ? id.id.to_i : id}
          friendly_ids, unfriendly_ids = ids.partition {|id| id.friendly_id?}
          return if friendly_ids.empty?
          records = friendly_records(friendly_ids, unfriendly_ids).each do |record|
            record.friendly_id_status.name = ids
          end
          validate_expected_size!(ids, records)
        end

        private

        def assign_status
          return unless @result
          name, seq = id.to_s.parse_friendly_id
          @result.friendly_id_status.name = name
          @result.friendly_id_status.sequence = seq if fc.use_slugs?
          @result
        end

        def find_one_without_slug
          @result = where(fc.column => id).first
          assign_status
        end

        def find_one_with_cached_slug
          @result = where(fc.cache_column => id).first
          assign_status or find_one_with_slug
        end

        def find_one_with_slug
          sluggable_ids = sluggable_ids_for([id])

          if sluggable_ids.size > 1 && fc.scope?
            return relation.where(relation.primary_key.in(sluggable_ids)).first
          end

          sluggable_id = sluggable_ids.first

          if sluggable_id
            name, seq = id.to_s.parse_friendly_id
            record = relation.send(:find_one_without_friendly, sluggable_id)
            record.friendly_id_status.name     = name
            record.friendly_id_status.sequence = seq
            record
          else
            relation.send(:find_one_without_friendly, id)
          end
        end

        def friendly_records(friendly_ids, unfriendly_ids)
          use_slugs_table =  fc.use_slugs? && (!fc.cache_column?)
          return find_some_using_slug(friendly_ids, unfriendly_ids) if use_slugs_table
          column     = fc.cache_column || fc.column
          friendly   = arel_table[column].in(friendly_ids)
          unfriendly = arel_table[relation.primary_key.name].in unfriendly_ids
          if friendly_ids.present? && unfriendly_ids.present?
            where(friendly.or(unfriendly))
          else
            where(friendly)
          end
        end

        def find_some_using_slug(friendly_ids, unfriendly_ids)
          ids = [unfriendly_ids + sluggable_ids_for(friendly_ids)].flatten.uniq
          where(arel_table[relation.primary_key.name].in(ids))
        end

        def sluggable_ids_for(ids)
          return [] if ids.empty?
          fragment = "(slugs.sluggable_type = %s AND slugs.name = %s AND slugs.sequence = %d)"
          conditions = ids.inject(nil) do |clause, id|
            name, seq = id.parse_friendly_id
            string = fragment % [connection.quote(klass.base_class), connection.quote(name), seq]
            clause ? clause + " OR #{string}" : string
          end
          sql = "SELECT sluggable_id FROM slugs WHERE (%s)" % conditions
          connection.select_values sql
        end

        def validate_expected_size!(ids, result)
          expected_size =
            if limit_value && ids.size > limit_value
              limit_value
            else
              ids.size
            end

          # 11 ids with limit 3, offset 9 should give 2 results.
          if offset_value && (ids.size - offset_value < expected_size)
            expected_size = ids.size - offset_value
          end

          if result.size == expected_size
            result
          else
            conditions = arel.send(:where_clauses).join(', ')
            conditions = " [WHERE #{conditions}]" if conditions.present?
            error = "Couldn't find all #{klass.name.pluralize} with IDs "
            error << "(#{ids.join(", ")})#{conditions} (found #{result.size} results, but was looking for #{expected_size})"
            raise ActiveRecord::RecordNotFound, error
          end
        end
      end

      protected

      def find_one(id)
        begin
          return super if !klass.uses_friendly_id? or id.unfriendly_id?
          find = Find.new(self, id)
          find.find_one or super
        end
      end

      def find_some(ids)
        return super unless klass.uses_friendly_id?
        Find.new(self, ids).find_some or begin
          # A change in Arel 2.0.x causes find_some to fail with arrays of instances; not sure why.
          # This is an emergency, temporary fix.
          ids = ids.map {|id| (id.respond_to?(:friendly_id_config) ? id.id : id).to_i}
          super
        end
      end
    end
  end
end