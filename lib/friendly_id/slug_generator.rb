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
      conflict? ? self.next : normalized
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
      unless defined? @conflict
        @conflict = conflicts.first
      end
      @conflict
    end

    def conflicts
      sluggable_class = friendly_id_config.model_class

      pkey  = sluggable_class.primary_key
      value = sluggable.send pkey
      scope = sluggable_class.unscoped.where("#{column} = ? OR #{column} LIKE ?", normalized, wildcard)
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
