module FriendlyId
  # The default slug generator offers functionality to check slug strings for
  # uniqueness and, if necessary, appends a sequence to guarantee it.
  class SlugGenerator
    attr_reader :sluggable, :normalized

    # Create a new slug generator.
    def initialize(sluggable, normalized)
      @sluggable  = sluggable
      @normalized = normalized
    end

    # Given a slug, get the next available slug in the sequence.
    def next
      "#{normalized}#{separator}#{next_in_sequence}"
    end

    # Generate a new sequenced slug.
    def generate
      attempt_count = 0

      while conflict?
        attempt_count += 1
        attempt = sluggable.normalize_friendly_id sluggable.resolve_slug_conflict(attempt_count)

        if attempt.blank?
          @conflict = conflicts.first
          return self.next
        end

        @normalized = attempt
        @conflict = conflicts.first
      end

      normalized
    end

    private

    def next_in_sequence
      last_in_sequence == 0 ? 2 : last_in_sequence.next
    end

    def last_in_sequence
      @_last_in_sequence ||= extract_sequence_from_slug(conflict.to_param)
    end

    def extract_sequence_from_slug(slug)
      # Don't assume that the separator is unique in the slug.
      slug.gsub(/^#{Regexp.quote(normalized)}(#{Regexp.quote(separator)})?/, '').to_i
    end

    def column
      sluggable.connection.quote_column_name friendly_id_config.slug_column
    end

    def conflict?
      !! conflict
    end

    def conflict
      unless defined?(@conflict)
        @conflict = conflicts.first
      end
      @conflict
    end

    def conflicts
      sluggable_class = friendly_id_config.model_class.base_class

      pkey  = sluggable_class.primary_key
      value = sluggable.send pkey
      base = "#{column} = ? OR #{column} LIKE ?"
      # Awful hack for SQLite3, which does not pick up '\' as the escape character without this.
      base << "ESCAPE '\\'" if sluggable.connection.adapter_name =~ /sqlite/i
      scope = sluggable_class.unscoped.where(base, normalized, wildcard)
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
      # Underscores (matching a single character) and percent signs (matching
      # any number of characters) need to be escaped
      # (While this seems like an excessive number of backslashes, it is correct)
      "#{normalized}#{separator}".gsub(/[_%]/, '\\\\\&') + '%'
    end
  end
end
