module FriendlyId
  # Works out the next sequence number for a sequentially slugged record.
  #
  # This is the half of the sequential slug feature that does not touch the
  # database. {FriendlyId::SequentiallySlugged::Calculator} finds the slugs that
  # conflict with a candidate; deciding what the next slug should be happens
  # here.
  #
  # An instance holds nothing, so one can be shared by every model in a process:
  #
  #     FriendlyId::SequenceCalculator.new.call("foo", ["foo", "foo-2"])
  #     #=> "foo-3"
  class SequenceCalculator
    # @param slug [String] the candidate a sequence is appended to.
    # @param conflicts [Array<String>] slugs that already exist and that may
    #   carry a sequence.
    # @param separator [String] what separates a slug from its sequence.
    def call(slug, conflicts, separator: "-")
      slug + separator + next_sequence_number(slug, conflicts, separator).to_s
    end

    private def next_sequence_number(slug, conflicts, separator)
      last = last_sequence_number(slug, conflicts, separator)
      last ? last + 1 : 2
    end

    # Ignores conflicts that do not derive from this candidate, then takes the
    # highest sequence number seen.
    private def last_sequence_number(slug, conflicts, separator)
      pattern = regexp(slug, separator)
      conflicts.filter_map { |conflict| pattern.match(conflict)&.[](1)&.to_i }.max
    end

    # Both halves are escaped because `separator` is configurable and
    # `normalize_friendly_id` can be overridden to emit anything. Interpolated
    # raw, a separator of "+" gives /foo+(\d+)\z/, which does not match "foo+2",
    # and an unbalanced "(" raises RegexpError.
    #
    # The \A matters because a caller may pass conflicts this class did not
    # select: without it, "barfoo-7" matches the pattern for base "foo".
    private def regexp(slug, separator)
      /\A#{Regexp.escape(slug)}#{Regexp.escape(separator)}(\d+)\z/
    end
  end
end
