# frozen_string_literal: true

require "hanami/cli"

module FriendlyId
  module Hanami
    # `hanami generate friendly_id`, which writes the migration and relation the
    # `:history` addon needs.
    #
    # Hanami has no way for a gem to register a ROM relation into an application:
    # `Hanami::Providers::DB#register_rom_components` globs `app/relations/**/*.rb`
    # and derives each constant from the file path, so a class living in this gem
    # is unreachable. Writing a small relation file into the application is the
    # supported shape, and it matches how the Rails generator writes a migration
    # into `db/migrate`.
    class CLI < ::Hanami::CLI::Commands::App::Command
      desc "Generate the friendly_id slugs migration and relation"

      option :skip_migration, type: :flag, default: false, desc: "Don't generate the migration"
      option :skip_relation, type: :flag, default: false, desc: "Don't generate the relation"
      option :force, type: :flag, default: false, desc: "Overwrite existing files"

      def call(skip_migration: false, skip_relation: false, force: false, **)
        write_migration(force) unless skip_migration
        write_relation(force) unless skip_relation
      end

      private

      # `fs.create` reports "Created <path>" itself and refuses to clobber an
      # existing file unless forced, which is how Hanami's own generators behave.
      def write_migration(force)
        path = fs.join("config", "db", "migrate", "#{timestamp}_create_friendly_id_slugs.rb")
        fs.create(path, MIGRATION, force: force)
      end

      def write_relation(force)
        path = fs.join("app", "relations", "friendly_id_slugs.rb")
        fs.create(path, relation_source, force: force)
      end

      def timestamp
        Time.now.strftime("%Y%m%d%H%M%S")
      end

      def relation_source
        <<~RUBY
          # frozen_string_literal: true

          module #{app.namespace}
            module Relations
              class FriendlyIdSlugs < Hanami::DB::Relation
                schema :friendly_id_slugs, infer: true
              end
            end
          end
        RUBY
      end

      # Mirrors lib/friendly_id/migration.rb column for column, so an application
      # can share one table between the Active Record and ROM adapters.
      MIGRATION = <<~RUBY
        # frozen_string_literal: true

        ROM::SQL.migration do
          change do
            create_table :friendly_id_slugs do
              primary_key :id
              column :slug, String, null: false
              column :sluggable_id, Integer, null: false
              column :sluggable_type, String, size: 50
              column :scope, String
              column :created_at, Time

              index [:sluggable_type, :sluggable_id]
              index [:slug, :sluggable_type]
              index [:slug, :sluggable_type, :scope], unique: true
            end
          end
        end
      RUBY
    end
  end
end

Hanami::CLI.register "generate friendly_id", FriendlyId::Hanami::CLI
