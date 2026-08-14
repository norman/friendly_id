require "securerandom"
require "friendly_id/rom/slug_source"
require "friendly_id/rom/slug_scope"

module FriendlyId
  module Rom
    # Adds slug-aware writes to a ROM repository.
    #
    #     class PostRepo < ROM::Repository[:posts]
    #       include FriendlyId::Rom::Repo
    #     end
    #
    #     repo.create_with_slug(title: "Hello World")  #=> #<Post slug="hello-world">
    #
    # ROM structs are immutable and have no lifecycle callbacks, so unlike the
    # Active Record adapter there is no hook that can generate a slug behind your
    # back. Slugging is something you ask for.
    module Repo
      # Creates a record, generating a slug from the configured base attribute.
      #
      # Under `:history` the slug is also recorded in the slugs table, in the same
      # transaction as the row itself.
      # An explicitly supplied slug is taken as given, matching `update_with_slug`.
      # Passing `slug: nil` asks for one to be generated, which is also what
      # omitting it entirely does.
      def create_with_slug(attributes, relation = friendly_id_relation)
        config = friendly_id_config_for(relation)
        attributes = symbolize(attributes)

        unless attributes[config.slug_column]
          slug = generate_friendly_id(attributes, relation)
          attributes = attributes.merge(config.slug_column => slug)
        end

        transaction(relation) do
          record = relation.changeset(:create, attributes).commit
          record_slug(record, relation, config)
          record
        end
      end

      # Updates a record, regenerating the slug only when asked to: either the
      # slug is explicitly set to nil, or it is nil already.
      #
      # Changing the base attribute alone does *not* change the slug, which
      # matches the Active Record adapter. Slugs are public URLs, so silently
      # rewriting one when a title is edited breaks every inbound link to it.
      # Pass `slug: nil` to ask for a fresh slug.
      def update_with_slug(id, attributes, relation = friendly_id_relation)
        config = friendly_id_config_for(relation)
        current = symbolize(relation.by_pk(id).one)
        attributes = symbolize(attributes)

        # No such record: nothing to regenerate against, and the update below is
        # a no-op rather than a crash.
        if current && regenerate_slug?(attributes, config, current)
          # Fall back to the stored values so that a slug can be regenerated even
          # when the update does not mention the base attribute, and exclude this
          # record so that it does not conflict with itself.
          source = current.merge(attributes)
          scope = slug_scope(relation, config, source).excluding_primary_key(id)
          attributes = attributes.merge(config.slug_column => generate_friendly_id(source, relation, scope))
        end

        transaction(relation) do
          record = relation.by_pk(id).changeset(:update, attributes).commit
          record_slug(record, relation, config)
          record
        end
      end

      # Deletes a record and the slugs table rows belonging to it.
      #
      # This is the `:history` counterpart of Active Record's
      # `dependent: :destroy`. A foreign key would be preferable, since it cannot
      # be forgotten, but the slugs table is polymorphic and a foreign key
      # constrains every row in a table, so no single key can serve rows pointing
      # at different tables. Active Record solves it in the application layer for
      # exactly the same reason.
      def delete_with_slug(id, relation = friendly_id_relation)
        config = friendly_id_config_for(relation)

        transaction(relation) do
          if config.history? && (slugs = slugs_relation(config))
            slugs
              .where(sluggable_type: config.sluggable_type_for(relation), sluggable_id: id)
              .delete
          end

          relation.by_pk(id).delete
        end
      end

      # Finds a record by its current slug, falling back to the slugs table when
      # `:history` is in use, so that a retired slug still resolves.
      def friendly_find(slug, relation = friendly_id_relation)
        relation.by_friendly_id(slug).one || find_by_historic_slug(slug, relation)
      end

      def friendly_find!(slug, relation = friendly_id_relation)
        friendly_find(slug, relation) or
          raise ROM::TupleCountMismatchError, "#{relation.name} does not have a record with the friendly id #{slug.inspect}"
      end

      # Generates a slug without writing anything, which is useful for previews
      # and for callers doing their own persistence.
      def generate_friendly_id(attributes, relation = friendly_id_relation, scope = nil)
        config = friendly_id_config_for(relation)
        attributes = symbolize(attributes)
        source = SlugSource.new(config, attributes)

        unless source.respond_to?(config.base)
          raise FriendlyId::ConfigurationError,
            "Cannot generate a slug: no :#{config.base} attribute was given, and it is " \
            "this relation's FriendlyId :base. Provide it, or set the slug yourself."
        end

        scope ||= slug_scope(relation, config, attributes)
        candidates = FriendlyId::Candidates.new(source, source.public_send(config.base))

        generator = FriendlyId::SlugGenerator.new(scope, config)
        generator.generate(candidates) || resolve_friendly_id_conflict(candidates, relation, scope)
      end

      # Called when every candidate is taken. Appends a sequence when the
      # `:sequentially_slugged` addon is in use, and a UUID otherwise, matching
      # the Active Record adapter.
      def resolve_friendly_id_conflict(candidates, relation = friendly_id_relation, scope = nil)
        config = friendly_id_config_for(relation)
        scope ||= slug_scope(relation, config, {})
        candidate = candidates.first

        if config.sequential?
          # Without a candidate there is nothing to append a sequence to. The
          # Active Record adapter returns nil here too.
          return if candidate.nil?

          FriendlyId::SequenceCalculator
            .new(candidate, config.sequence_separator)
            .next_slug(scope.conflict_slugs(candidate))
        else
          # A nil candidate yields a bare UUID, which is what the Active Record
          # adapter produces for a base that cannot be sluggified at all, such as
          # "!!!" or a CJK-only title.
          uuid = SecureRandom.uuid
          [apply_slug_limit(candidate, uuid, config), uuid].compact.join(config.sequence_separator)
        end
      end

      private

      # The relation FriendlyId operates on. Defaults to the repository's root,
      # which is what ROM::Repository[:posts] and Hanami::DB::Repo provide.
      def friendly_id_relation
        relation = respond_to?(:root) ? root : nil

        if relation.nil?
          raise FriendlyId::ConfigurationError, "#{self.class} has no root relation. Declare one, " \
            "e.g. `class PostRepo < ROM::Repository[:posts]` or " \
            "`class PostRepo < Hanami::DB::Repo[:posts]`, or pass the relation as the last " \
            "argument. Note that a bare `< Hanami::DB::Repo` does not infer a root from the " \
            "class name."
        end

        relation
      end

      def friendly_id_config_for(relation)
        unless relation.respond_to?(:friendly_id_config)
          raise FriendlyId::ConfigurationError, "Relation #{relation.name.inspect} is not configured for FriendlyId. " \
            "Add `use :friendly_id, base: :some_column` to it."
        end

        relation.friendly_id_config
      end

      def slug_scope(relation, config, attributes)
        SlugScope.new(
          relation,
          config,
          slugs: config.history? ? slugs_relation(config) : nil,
          sluggable_type: config.sluggable_type_for(relation),
          scope_values: scope_values(config, attributes)
        )
      end

      def scope_values(config, attributes)
        return {} unless config.scoped?

        config.scope_columns.each_with_object({}) { |col, out| out[col] = attributes[col] }
      end

      # The slugs table, resolved from the container by name so that neither the
      # gem nor the sluggable relation needs a reference to it.
      def slugs_relation(config)
        container.relations[config.slugs_relation]
      rescue KeyError, ROM::ElementNotFoundError
        raise FriendlyId::ConfigurationError,
          "FriendlyId's :history addon needs a :#{config.slugs_relation} relation, and none is " \
          "registered. In a Hanami app run `hanami generate friendly_id`; in a plain ROM app " \
          "register a relation with `schema(:#{config.slugs_relation}, infer: true)`."
      end

      # Records the current slug in the slugs table, unless it is already the
      # latest one recorded. A slug the record used before is removed first, so
      # that reverting to it works and the unique index is not violated.
      def record_slug(record, relation, config)
        return record unless config.history?
        return record if record.nil?

        attributes = symbolize(record)
        slug = attributes[config.slug_column]
        return record if slug.nil?

        slugs = slugs_relation(config)
        type = config.sluggable_type_for(relation)
        id = attributes[relation.schema.primary_key_name]

        owned = slugs.where(sluggable_type: type, sluggable_id: id)
        return record if owned.order(Sequel.desc(:id)).limit(1).pluck(:slug).first == slug

        owned.where(slug: slug).delete

        row = {slug: slug, sluggable_type: type, sluggable_id: id, created_at: Time.now}
        row[:scope] = Rom.serialized_scope(config, scope_values(config, attributes)) if config.scoped?
        slugs.changeset(:create, row).commit

        record
      end

      def find_by_historic_slug(slug, relation)
        config = friendly_id_config_for(relation)
        return nil unless config.history?

        ids = slugs_relation(config)
          .where(sluggable_type: config.sluggable_type_for(relation), slug: slug)
          .order(Sequel.desc(:id))
          .pluck(:sluggable_id)

        return nil if ids.empty?

        relation.by_pk(ids.first).one
      end

      # Mirrors `Slugged#should_generate_new_friendly_id?`, which regenerates
      # only when the slug is nil. See the note on `update_with_slug`.
      def regenerate_slug?(attributes, config, current)
        # An explicit `slug: nil` asks for a fresh slug.
        return attributes[config.slug_column].nil? if attributes.key?(config.slug_column)

        # A record with no slug yet, for instance one written by plain `create`
        # or by a migration, gets one on its next update.
        current[config.slug_column].nil?
      end

      def transaction(relation, &block)
        relation.transaction(&block)
      end

      # ROM relations yield hashes, repositories yield structs. Accept either.
      def symbolize(record)
        return nil if record.nil?

        pairs = record.respond_to?(:to_h) ? record.to_h : record
        pairs.each_with_object({}) { |(key, value), out| out[key.to_sym] = value }
      end

      def apply_slug_limit(candidate, uuid, config)
        return candidate unless candidate && config.slug_limit

        limit = [config.slug_limit - uuid.size - config.sequence_separator.size, 0].max
        candidate[0...limit]
      end
    end
  end
end
