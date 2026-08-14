# frozen_string_literal: true

require "tmpdir"
require "fileutils"

ENV["HANAMI_ENV"] = "test"

# Hanami derives the test database name from DATABASE_URL (it appends "_test"),
# so rather than guessing that convention this prepares the :db provider, creates
# the schema on whatever connection Hanami resolved, and only then boots. Boot is
# when relations infer their schemas, so the tables have to exist by that point.
#
# A file-backed database rather than :memory: because each SQLite in-memory
# connection gets its own separate database.
TMP_DIR = Dir.mktmpdir("friendly_id-hanami")
ENV["DATABASE_URL"] = "sqlite://#{File.join(TMP_DIR, "smoke.sqlite3")}"

require "bundler/setup"
require "minitest/autorun"

require_relative "../config/app"
require "hanami/prepare"

Hanami.app.prepare(:db)

Hanami.app["db.gateway"].connection.then do |db|
  db.create_table?(:posts) do
    primary_key :id
    column :title, String, null: false
    column :slug, String, null: false
    index :slug, unique: true
  end

  db.create_table?(:articles) do
    primary_key :id
    column :title, String, null: false
    column :section_id, Integer, null: false
    column :slug, String
    index %i[section_id slug], unique: true
  end

  db.create_table?(:authors) do
    primary_key :id
    column :name, String, null: false
    column :slug, String, null: false
    index :slug, unique: true
  end
end

# `friendly_id_slugs` is created by running the migration that
# `hanami generate friendly_id` writes, rather than by hand. That way the
# generated migration is exercised on every run instead of being assumed to work,
# and the table can never drift from what the generator emits.
#
# `ROM::SQL.migration` needs a current gateway, so Sequel's migrator has to run
# inside `with_gateway`. Passing `path:` to `run_migrations` does not work: that
# option is forwarded to Sequel, while the migrator takes its path from gateway
# config.
require "sequel"
Sequel.extension :migration

MIGRATIONS = File.expand_path("../config/db/migrate", __dir__)

ROM::SQL.with_gateway(Hanami.app["db.gateway"]) do
  Sequel::Migrator.run(Hanami.app["db.gateway"].connection, MIGRATIONS)
end

Hanami.app.boot

Minitest.after_run { FileUtils.remove_entry(TMP_DIR) if File.directory?(TMP_DIR) }

module SmokeTest
  module_function

  def app = Hanami.app
  def connection = app["db.gateway"].connection

  def clean!
    %i[posts authors articles friendly_id_slugs].each { |table| connection[table].delete }
  end

  def posts = app["repos.post_repo"]
  def articles = app["repos.article_repo"]
  def slugs = app["relations.friendly_id_slugs"]
  def authors = app["repos.author_repo"]
end
