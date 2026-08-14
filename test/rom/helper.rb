require "bundler/setup"

begin
  require "minitest"
rescue LoadError
  require "minitest/unit"
end

begin
  TestCaseClass = Minitest::Test
rescue NameError
  TestCaseClass = Minitest::Unit::TestCase
end

require "minitest/autorun"

require "rom"
require "friendly_id/rom"

if defined?(ActiveRecord)
  abort "Active Record was loaded by the ROM test suite, which defeats its purpose."
end

module FriendlyId
  module Test
    module Rom
      TABLES = %i[
        posts articles drafts chapters lessons translations friendly_id_slugs custom_slugs
      ].freeze

      # Set DATABASE_URL to any Sequel connection string to run against a
      # server. SQLite exercises neither the LIKE ESCAPE clause nor a
      # case-insensitive collation the way MySQL and PostgreSQL do.
      def self.url
        ENV.fetch("DATABASE_URL", "sqlite::memory:")
      end

      # Shared by every container, or each would try to create the same tables.
      def self.connection
        @connection ||= Sequel.connect(url).tap { |db| create_schema(db) }
      end

      # Keyed because ROM registers a relation under its schema name, and these
      # files need different FriendlyId configurations for the same table.
      def self.container(key = :default, &relations)
        @containers ||= {}
        @containers[key] ||= begin
          config = ROM::Configuration.new(:sql, connection)
          yield(config) if relations
          ROM.container(config)
        end
      end

      def self.create_schema(db)
        TABLES.reverse_each { |table| db.drop_table?(table) }

        db.create_table(:posts) do
          primary_key :id
          column :title, String, null: false
          column :slug, String, null: false
          index :slug, unique: true
        end

        db.create_table(:articles) do
          primary_key :id
          column :title, String, null: false
          column :slug, String, null: false
        end

        # A nullable slug column, as an application backfilling one has.
        db.create_table(:drafts) do
          primary_key :id
          column :title, String
          column :slug, String
        end

        db.create_table(:chapters) do
          primary_key :id
          column :title, String, null: false
          column :book_id, Integer, null: false
          column :slug, String
          index %i[book_id slug], unique: true
        end

        db.create_table(:lessons) do
          primary_key :id
          column :title, String, null: false
          column :course_id, Integer, null: false
          column :unit_id, Integer, null: false
          column :slug, String
          index %i[course_id unit_id slug], unique: true
        end

        db.create_table(:translations) do
          primary_key :id
          column :title, String, null: false
          column :slug_en, String
          column :slug_fr, String
          column :slug_pt_br, String
        end

        # Matches lib/friendly_id/migration.rb so one table can serve both adapters.
        db.create_table(:friendly_id_slugs) do
          primary_key :id
          column :slug, String, null: false
          column :sluggable_id, Integer, null: false
          column :sluggable_type, String, size: 50
          column :scope, String
          column :created_at, Time
          index %i[sluggable_type sluggable_id]
          index %i[slug sluggable_type]
          index %i[slug sluggable_type scope], unique: true
        end

        db.create_table(:custom_slugs) do
          primary_key :id
          column :slug, String, null: false
          column :sluggable_id, Integer, null: false
          column :sluggable_type, String, size: 50
          column :scope, String
          column :created_at, Time
          index %i[slug sluggable_type scope], unique: true
        end
      end

      # Goes through the connection, because a table can back more than one
      # relation and may back none at all in a given container.
      def self.clean!(key = :default)
        container(key)
        TABLES.each { |table| connection[table].delete }
      end
    end
  end
end

class Module
  def test(name, &block)
    define_method(:"test_#{name.gsub(/[^a-z0-9']/i, "_")}", &block)
  end
end
