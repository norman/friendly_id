class ActiveRecord::Relation
  alias original_find_one  find_one
  alias original_find_some find_some
end


module FriendlyId
  module ActiveRecordAdapter
    module Relation

      attr :friendly_id_scope

      def apply_finder_options(options)
        @friendly_id_scope = options.delete(:scope)
        @friendly_id_scope = @friendly_id_scope.to_param if @friendly_id_scope.respond_to?(:to_param)
        super
      end

      protected

      def find_one(id)
        return super if !@klass.uses_friendly_id? or id.unfriendly_id?
        return slugged_find_one(id) if friendly_id_config.use_slugs? && !friendly_id_config.cache_column?
        column = friendly_id_config.cache_column or friendly_id_config.column
        record = where(column => id).first
        if record
          name, seq = id.to_s.parse_friendly_id
          record.friendly_id_status.name = name
          record.friendly_id_status.sequence = seq
          record
        elsif friendly_id_config.use_slugs?
          slugged_find_one(id)
        else
          super
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

      def slugged_find_one(id)
        name, seq = id.to_s.parse_friendly_id
        record = joins(:slugs).where(:slugs => {:name => name, :sequence => seq, :scope => friendly_id_scope}).order("slugs.id DESC").first
        if record
          record.friendly_id_status.name = name
          record.friendly_id_status.sequence = seq
          record
        else
          original_find_one(id)
        end
      end

      private

      def friendly_records(friendly_ids, unfriendly_ids)
        column     = friendly_id_config.cache_column or friendly_id_config.column
        friendly   = if friendly_id_config.use_slugs? and !friendly_id_config.cache_column?
            slugged_conditions(friendly_ids)
          else
            arel_table[column].in friendly_ids
          end
        unfriendly = arel_table[primary_key].in unfriendly_ids
        clause = nil
        if friendly_ids.present? && unfriendly_ids.present?
          clause = friendly.or(unfriendly)
        elsif friendly_ids.present?
          clause = friendly
        elsif unfriendly_ids.present?
          clause = unfriendly
        end
        if friendly_id_config.use_slugs? and !friendly_id_config.cache_column?
          joins(:slugs).where(clause)
        else
          where(clause)
        end
      end
      
      def slugged_conditions(ids)
        return if ids.empty?
        slugs = Slug.arel_table
        name, seq = ids[0].parse_friendly_id
        clause = slugs[:name].eq(name).and(slugs[:sequence].eq(seq)).and(slugs[:scope].eq(friendly_id_scope))
        ids.each_with_index do |id, index|
          next if index == 0
          name, seq = id.parse_friendly_id
          clause = clause.or(slugs[:name].eq(name).and(slugs[:sequence].eq(seq)))
        end
        clause
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