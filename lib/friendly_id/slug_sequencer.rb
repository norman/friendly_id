module FriendlyId
  # This class offers functionality to check slug strings for uniqueness and,
  # if necessary, append a sequence to ensure it.
  class SlugSequencer
    attr_reader :sluggable, :normalized

    def initialize(sluggable, normalized)
      @sluggable  = sluggable
      @normalized = normalized
    end

    # Given a slug, get the next available slug in the sequence.
    def next
      sequence = conflict.to_param.split(separator)[1].to_i
      next_sequence = sequence == 0 ? 2 : sequence.next
      "#{normalized}#{separator}#{next_sequence}"
    end

    # Generate a new sequenced slug.
    def generate
      conflict? ? self.next : normalized
    end

    private

    def column
      sluggable.connection.quote_column_name friendly_id_config.slug_column
    end

    def conflict?
      !! conflict
    end

    def conflict
      unless defined? @conflict
        @conflict = conflicts.first
      end
      @conflict
    end

    def conflicts
      pkey  = sluggable.class.primary_key
      value = sluggable.send pkey
      scope = sluggable.class.unscoped.where("#{column} = ? OR #{column} LIKE ?", normalized, wildcard)
      scope = scope.where("#{pkey} <> ?", value) unless sluggable.new_record?
      scope = scope.order("LENGTH(#{column}) DESC, #{column} DESC")
    end

    def friendly_id_config
      sluggable.friendly_id_config
    end

    def separator
      friendly_id_config.sequence_separator
    end

    def wildcard
      "#{normalized}#{separator}%"
    end
  end
end
