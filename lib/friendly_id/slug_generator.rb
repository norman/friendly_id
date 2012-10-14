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
      slug.split("#{normalized}#{separator}").last.to_i
    end

    def column
      sluggable.connection.quote_column_name friendly_id_config.slug_column
    end

    def conflict?
      !! (direct_conflict && conflict)
    end

    def direct_conflict
      @direct_conflict ||= direct_conflicts.first
    end

    def conflict
      @conflict ||= conflicts.first
    end

    def sluggable_class
      friendly_id_config.model_class.base_class
    end

    def sluggable_primary_key_column
      sluggable_class.primary_key
    end

    def sluggable_primary_key
      sluggable.send(sluggable_primary_key_column)
    end

    def direct_conflicts
      base = "#{column} = ?"
      scope = sluggable_class.unscoped.where(base, normalized)
      scope_excluding_sluggable(scope)
    end

    def conflicts
      base = query_with_sqlite_hack("#{column} = ? OR #{column} LIKE ?")
      scope = sluggable_class.unscoped.where(base, normalized, wildcard)
      scope = scope.order("LENGTH(#{column}) DESC, #{column} DESC")
      scope_excluding_sluggable(scope)
    end

    def scope_excluding_sluggable(scope)
      if sluggable.new_record?
        scope
      else
        scope.where("#{sluggable_primary_key_column} <> ?", sluggable_primary_key)
      end
    end

    def query_with_sqlite_hack(query)
      # Awful hack for SQLite3, which does not pick up '\' as the escape character without this.
      query << "ESCAPE '\\'" if sluggable.connection.adapter_name =~ /sqlite/i
      query
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
