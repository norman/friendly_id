# frozen_string_literal: true

require_relative "helper"
require "friendly_id/hanami/cli"
require "tmpdir"

# Exercises `hanami generate friendly_id`.
#
# The command is driven directly rather than through the `hanami` executable so
# that it can write into a temporary directory: running it in place would add a
# second, differently timestamped migration on every run. That the command is
# reachable from the real binary is covered separately, by the fact that
# `hanami generate --help` lists it.
#
# The generated files themselves are exercised on every run of the whole suite,
# because test/helper.rb runs the committed migration and Hanami boots the
# committed relation.
class GeneratorTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir("friendly_id-generator")
    @out = StringIO.new
    @command = FriendlyId::Hanami::CLI.new(
      fs: Hanami::CLI::Files.new(out: @out),
      out: @out
    )
  end

  def teardown
    FileUtils.remove_entry(@dir) if File.directory?(@dir)
  end

  def generate(**opts)
    Dir.chdir(@dir) { @command.call(**opts) }
  end

  def migration_path
    Dir[File.join(@dir, "config", "db", "migrate", "*_create_friendly_id_slugs.rb")].first
  end

  def relation_path
    File.join(@dir, "app", "relations", "friendly_id_slugs.rb")
  end

  def test_writes_a_timestamped_migration
    generate

    refute_nil migration_path, "no migration was written"
    assert_match(/\A\d{14}_create_friendly_id_slugs\.rb\z/, File.basename(migration_path))
  end

  def test_the_migration_is_a_rom_migration
    generate

    source = File.read(migration_path)
    assert_match(/ROM::SQL\.migration do/, source)
    assert_match(/create_table :friendly_id_slugs/, source)
  end

  # The columns must match lib/friendly_id/migration.rb so that one table can be
  # shared between the Active Record and ROM adapters.
  def test_the_migration_matches_the_active_record_schema
    generate

    source = File.read(migration_path)
    %w[slug sluggable_id sluggable_type scope created_at].each do |column|
      assert_match(/column :#{column}\b/, source, "missing column #{column}")
    end
    assert_match(/index \[:slug, :sluggable_type, :scope\], unique: true/, source)
  end

  def test_writes_a_relation_in_the_apps_namespace
    generate

    source = File.read(relation_path)
    assert_match(/module HanamiApp/, source)
    assert_match(/class FriendlyIdSlugs < Hanami::DB::Relation/, source)
    assert_match(/schema :friendly_id_slugs, infer: true/, source)
  end

  def test_skip_flags
    generate(skip_migration: true, skip_relation: true)

    assert_nil migration_path
    refute File.exist?(relation_path)
  end

  # Hanami's own generators refuse to clobber. `Command::Environment`, which is
  # prepended to every app command, turns FileAlreadyExistsError into a message
  # on stderr and `exit(1)` rather than a stack trace, so that is what a caller
  # sees and what this asserts.
  def test_refuses_to_overwrite_without_force
    generate(skip_migration: true)

    err = StringIO.new
    @command = FriendlyId::Hanami::CLI.new(
      fs: Hanami::CLI::Files.new(out: @out), out: @out, err: err
    )

    assert_raises(SystemExit) { generate(skip_migration: true) }
    assert_match(/already exists/, err.string)
  end

  def test_force_overwrites
    generate(skip_migration: true)
    File.write(relation_path, "# clobbered\n")

    generate(skip_migration: true, force: true)

    assert_match(/class FriendlyIdSlugs/, File.read(relation_path))
  end
end
