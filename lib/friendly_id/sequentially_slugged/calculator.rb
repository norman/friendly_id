module FriendlyId
  module SequentiallySlugged
    # Finds the slugs that conflict with a candidate. Deciding which sequence
    # the next slug gets belongs to the configured
    # {FriendlyId::SequentiallySlugged::Configuration#sequence_calculator
    # sequence_calculator}, which never sees the database.
    #
    # Everything here is Active Record specific: quoting, the SQLite `ESCAPE`
    # workaround and the SQL Server `LEN` spelling.
    class Calculator
      attr_accessor :scope, :slug, :slug_column, :sequence_separator

      def initialize(scope, slug, slug_column, sequence_separator, base_class)
        @scope = scope
        @slug = slug
        table_name = scope.connection.quote_table_name(base_class.arel_table.name)
        @slug_column = "#{table_name}.#{scope.connection.quote_column_name(slug_column)}"
        @sequence_separator = sequence_separator
      end

      # The slugs already taken that could carry a sequence for this candidate.
      def slug_conflicts
        scope
          .where(conflict_query, slug, sequential_slug_matcher)
          .order(Arel.sql(ordering_query)).pluck(Arel.sql(slug_column))
      end

      private

      def conflict_query
        base = "#{slug_column} = ? OR #{slug_column} LIKE ?"
        # Awful hack for SQLite3, which does not pick up '\' as the escape character
        # without this.
        base << " ESCAPE '\\'" if /sqlite/i.match?(scope.connection.adapter_name)
        base
      end

      # Return the unnumbered (shortest) slug first, followed by the numbered ones
      # in ascending order.
      def ordering_query
        "#{sql_length}(#{slug_column}) ASC, #{slug_column} ASC"
      end

      def sequential_slug_matcher
        # Underscores (matching a single character) and percent signs (matching
        # any number of characters) need to be escaped. While this looks like
        # an excessive number of backslashes, it is correct.
        "#{slug}#{sequence_separator}".gsub(/[_%]/, '\\\\\&') + "%"
      end

      def sql_length
        /sqlserver/i.match?(scope.connection.adapter_name) ? "LEN" : "LENGTH"
      end
    end
  end
end
