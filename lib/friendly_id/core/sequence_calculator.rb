module FriendlyId
  # Works out the next sequence number for a sequentially slugged record.
  #
  # This is the persistence-independent half of the sequential slug feature.
  # Adapters are responsible only for finding the slugs that conflict with a
  # given candidate; deciding what the next slug should be happens here.
  #
  #     FriendlyId::SequenceCalculator.new("foo", "-").next_slug(["foo", "foo-2"])
  #     #=> "foo-3"
  class SequenceCalculator
    attr_reader :slug, :sequence_separator

    def initialize(slug, sequence_separator)
      @slug = slug
      @sequence_separator = sequence_separator
    end

    # @param conflicts [Array<String>] slugs that already exist and that may
    #   carry a sequence, as found by the adapter.
    def next_slug(conflicts)
      slug + sequence_separator + next_sequence_number(conflicts).to_s
    end

    def next_sequence_number(conflicts)
      last = last_sequence_number(conflicts)
      last ? last + 1 : 2
    end

    # Ignores conflicts that do not derive from this candidate, then takes the
    # highest sequence number seen.
    def last_sequence_number(conflicts)
      conflicts.filter_map { |conflict| regexp.match(conflict)&.[](1)&.to_i }.max
    end

    private

    # Both halves are escaped, and the pattern is anchored at both ends.
    #
    # Escaping matters because `sequence_separator` is configurable. Interpolated
    # raw, a separator of "." would give /foo.(\d+)\z/, whose "." matches any
    # character, so "foo-2" would count towards the sequence for base "foo". An
    # unbalanced "(" from a custom `normalize_friendly_id` would raise
    # RegexpError. Anchoring at the front matters because a caller may pass
    # conflicts this class did not select: without \A, "barfoo-7" matches the
    # pattern for base "foo".
    #
    # Neither value is ever user input: they come from the application's own
    # config and normalizer, and are matched against slugs already read from the
    # database.
    def regexp
      /\A#{Regexp.escape(slug)}#{Regexp.escape(sequence_separator)}(\d+)\z/
    end
  end
end
