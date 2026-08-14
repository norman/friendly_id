require "friendly_id/rom/configuration"

module FriendlyId
  module Rom
    # A ROM relation plugin adding FriendlyId's query methods and configuration.
    #
    #     class Posts < ROM::Relation[:sql]
    #       schema(:posts, infer: true)
    #       use :friendly_id, base: :title, use: [:sequentially_slugged]
    #     end
    #
    # ROM calls `.apply` with the relation class and the options given to `use`,
    # which is this adapter's equivalent of `friendly_id :title, use: :slugged`.
    module Relation
      def self.apply(relation_class, **options)
        relation_class.extend(ClassMethods)
        relation_class.include(InstanceMethods)
        relation_class.friendly_id_config = Configuration.new(options)
      end

      module ClassMethods
        attr_accessor :friendly_id_config

        # Relation subclasses would otherwise lose the configuration, since it
        # lives in a class-level instance variable.
        def inherited(subclass)
          super
          subclass.friendly_id_config = friendly_id_config
        end
      end

      module InstanceMethods
        def friendly_id_config
          self.class.friendly_id_config
        end

        # Present so that code reads the same as it does on Active Record, where
        # `friendly` returns a scope carrying the friendly finders. Here the
        # finders are always available, so this is the relation itself.
        def friendly
          self
        end

        def by_friendly_id(slug)
          where(friendly_id_config.slug_column => slug)
        end

        # The one method {FriendlyId::SlugGenerator} requires of a scope.
        def exists_by_friendly_id?(slug)
          !by_friendly_id(slug).limit(1).one.nil?
        end

        # Excludes a record from the relation, so that a record being updated
        # does not count its own slug as a conflict. The Active Record adapter
        # does the same in `scope_for_slug_generator`.
        def excluding_primary_key(value)
          return self if value.nil?

          exclude(schema.primary_key_name => value)
        end

        # Slugs that would collide with `base`, either exactly or as `base-<n>`.
        # Feeds {FriendlyId::SequenceCalculator}.
        def conflict_slugs(base)
          column = friendly_id_config.slug_column
          separator = friendly_id_config.sequence_separator

          # `_` matches a single character and `%` any number of them, so both
          # have to be escaped before being used as a LIKE prefix.
          prefix = "#{base}#{separator}".gsub(/[_%]/) { |char| "\\#{char}" }

          where {
            Sequel.|(
              {column => base},
              Sequel.like(column, "#{prefix}%", esc: "\\")
            )
          }.pluck(column)
        end
      end
    end
  end
end
