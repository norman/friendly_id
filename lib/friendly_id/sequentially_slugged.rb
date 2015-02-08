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
        slug + sequence_separator + next_sequence_number.to_s
      end

    private

      def next_sequence_number
        if last_sequence_number == 0
          2
        else
          last_sequence_number + 1
        end
      end

      def last_sequence_number
        slug_conflicts.last.split("#{slug}#{sequence_separator}").last.to_i
      end

      def slug_conflicts
        scope.
          where(conflict_query, slug, sequential_slug_matcher).
          order(ordering_query).pluck(slug_column)
      end

      def conflict_query
        "#{slug_column} = ? OR #{slug_column} LIKE ?"
      end

      def sequential_slug_matcher
        "#{slug}#{sequence_separator}%"
      end

      # Return the unnumbered (shortest) slug first, followed by the numbered ones
      # in ascending order.
      def ordering_query
        "LENGTH(#{slug_column}) ASC, #{slug_column} ASC"
      end
    end
  end
end
