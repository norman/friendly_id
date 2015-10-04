module FriendlyId
  module SequentiallySlugged
    def self.setup(model_class)
      model_class.friendly_id_config.use :slugged
    end

    def should_generate_new_friendly_id?
      send(friendly_id_config.base).present? && super
    end

    def resolve_friendly_id_conflict(candidate_slugs)
      SequentialSlugCalculator.new(scope_for_slug_generator,
                                  candidate_slugs.first,
                                  friendly_id_config.slug_column,
                                  friendly_id_config.sequence_separator).next_slug
    end

    class SequentialSlugCalculator
      attr_accessor :scope, :slug, :slug_column, :sequence_separator

      def initialize(scope, slug, slug_column, sequence_separator)
        @scope = scope
        @slug = slug
        @slug_column = scope.connection.quote_column_name(slug_column)
        @sequence_separator = sequence_separator
      end

      def next_slug
        [slug, next_sequence_number].compact.join(sequence_separator)
      end

    private

      def next_sequence_number
        last_sequence_number ? last_sequence_number + 1 : 2
      end

      def last_sequence_number
        slug_conflicts.reverse_each do |conflict|
          match = /#{slug}#{sequence_separator}(\d+)\z/.match(conflict)
          return match[1].to_i if match
        end

        nil
      end

      def slug_conflicts
        scope.
          where(conflict_query, slug, sequential_slug_matcher).
          order(ordering_query).pluck(slug_column)
      end

      def conflict_query
        base = "#{slug_column} = ? OR #{slug_column} LIKE ?"
        # Awful hack for SQLite3, which does not pick up '\' as the escape character
        # without this.
        base << " ESCAPE '\\'" if scope.connection.adapter_name =~ /sqlite/i
        base
      end

      def sequential_slug_matcher
        # Underscores (matching a single character) and percent signs (matching
        # any number of characters) need to be escaped. While this looks like
        # an excessive number of backslashes, it is correct.
        "#{slug}#{sequence_separator}".gsub(/[_%]/, '\\\\\&') + '%'
      end

      # Return the unnumbered (shortest) slug first, followed by the numbered ones
      # in ascending order.
      def ordering_query
        length_command = "LENGTH"
        length_command = "LEN" if scope.connection.adapter_name =~ /sqlserver/i
        "#{length_command}(#{slug_column}) ASC, #{slug_column} ASC"
      end
    end
  end
end
