module FriendlyId
  module Rom
    # The scope {FriendlyId::SlugGenerator} checks candidates against.
    #
    # For a plain relation the relation itself is enough: it answers
    # `exists_by_friendly_id?`, which is the only method the protocol requires.
    # The `:history` and `:scoped` addons change the question being asked:
    #
    # * `:history` widens it. A slug any record used to have is still taken, or a
    #   new record would steal it and break the redirect the addon exists to
    #   preserve.
    # * `:scoped` narrows it. Two records may share a slug as long as they differ
    #   in the scope columns.
    #
    # Both are answered here rather than on the relation, because a ROM relation
    # has no way to reach another relation. The repository holds the whole
    # registry, so it builds this and hands it over.
    #
    # Note that `friendly_id_slugs.slug` is always called `slug`, whatever the
    # sluggable relation's own slug column is called. The history table stores
    # slug *values*, which is also why `:simple_i18n` needs nothing here.
    class SlugScope
      attr_reader :relation, :config, :slugs, :sluggable_type, :scope_values, :excluded_id

      def initialize(relation, config, slugs: nil, sluggable_type: nil, scope_values: {}, excluded_id: nil)
        @relation = relation
        @config = config
        @slugs = slugs
        @sluggable_type = sluggable_type
        @scope_values = scope_values
        @excluded_id = excluded_id
      end

      def exists_by_friendly_id?(slug)
        return true if scoped_relation.exists_by_friendly_id?(slug)

        history? && historic_slugs.where(slug: slug).exist?
      end

      # Slugs that would collide with `base`, either exactly or as `base-<n>`,
      # across both the relation and the history table.
      def conflict_slugs(base)
        found = scoped_relation.conflict_slugs(base)
        found += history_conflict_slugs(base) if history?
        found.uniq
      end

      # Excludes a record from its own conflict scope, so that regenerating an
      # unchanged record returns the same slug rather than incrementing forever.
      # The record's own historic slugs are excluded too, which is what lets it
      # revert to a slug it held before.
      def excluding_primary_key(value)
        self.class.new(
          relation.excluding_primary_key(value),
          config,
          slugs: slugs,
          sluggable_type: sluggable_type,
          scope_values: scope_values,
          excluded_id: value
        )
      end

      private

      def history?
        config.history? && !slugs.nil?
      end

      # Under `:scoped`, only records sharing this record's scope values compete
      # for a slug.
      def scoped_relation
        return relation unless config.scoped?

        config.scope_columns.reduce(relation) do |rel, column|
          rel.where(column => scope_values[column])
        end
      end

      def historic_slugs
        rows = slugs.where(sluggable_type: sluggable_type)
        rows = rows.exclude(sluggable_id: excluded_id) if excluded_id
        rows = rows.where(scope: Rom.serialized_scope(config, scope_values)) if config.scoped?
        rows
      end

      def history_conflict_slugs(base)
        separator = config.sequence_separator

        # `_` matches a single character and `%` any number of them, so both have
        # to be escaped before being used as a LIKE prefix.
        prefix = "#{base}#{separator}".gsub(/[_%]/) { |char| "\\#{char}" }

        historic_slugs.where {
          Sequel.|({slug: base}, Sequel.like(:slug, "#{prefix}%", esc: "\\"))
        }.pluck(:slug)
      end
    end
  end
end
