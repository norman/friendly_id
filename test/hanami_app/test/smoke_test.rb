# frozen_string_literal: true

require_relative "helper"

# Proves the things the ROM unit tests cannot: that FriendlyId survives a real
# Hanami boot, that its relation plugin is applied through Hanami's component
# registration, and that slugs round-trip through a booted application.
class HanamiSmokeTest < Minitest::Test
  def setup
    SmokeTest.clean!
  end

  def test_the_app_boots_with_friendly_id_loaded
    assert Hanami.app.booted?
    assert defined?(FriendlyId::Rom), "FriendlyId's ROM adapter should be loaded"
  end

  def test_the_relation_plugin_survived_hanami_boot
    relation = Hanami.app["relations.posts"]

    assert_respond_to relation, :friendly_id_config
    assert_respond_to relation, :by_friendly_id
    assert_respond_to relation, :exists_by_friendly_id?
    assert_equal :title, relation.friendly_id_config.base
    assert relation.friendly_id_config.sequential?
  end

  def test_hanami_db_relation_really_is_a_rom_relation
    assert_kind_of ROM::Relation, Hanami.app["relations.posts"]
    assert_kind_of ROM::Repository, Hanami.app["repos.post_repo"]
  end

  def test_creates_a_slug_through_the_repo
    post = SmokeTest.posts.create_with_slug(title: "Hello From Hanami")

    assert_equal "hello-from-hanami", post.slug
    assert_equal "Hello From Hanami", post.title
  end

  def test_finds_a_record_by_slug
    SmokeTest.posts.create_with_slug(title: "Round Trip")

    assert_equal "Round Trip", SmokeTest.posts.find_by_slug!("round-trip").title
    assert_equal "Round Trip", SmokeTest.posts.friendly_find("round-trip").title
  end

  def test_sequential_conflicts_resolve_in_a_real_app
    3.times { SmokeTest.posts.create_with_slug(title: "Same Title") }

    assert_equal %w[same-title same-title-2 same-title-3], SmokeTest.posts.all_slugs.sort
  end

  def test_uuid_conflicts_on_a_relation_without_sequences
    assert_equal "ada-lovelace", SmokeTest.authors.create_with_slug(name: "Ada Lovelace").slug
    assert_match(/\Aada-lovelace-[0-9a-f]{8}-/, SmokeTest.authors.create_with_slug(name: "Ada Lovelace").slug)
  end

  def test_reserved_words_are_honoured_in_a_real_app
    assert_match(/\Aadmin-[0-9a-f]{8}-/, SmokeTest.authors.create_with_slug(name: "admin").slug)
  end

  def test_normalisation_works_without_active_support
    refute defined?(ActiveSupport::VERSION), "Active Support should not be loaded in a Hanami app"

    assert_equal "cafe-del-mar", SmokeTest.posts.create_with_slug(title: "Café del Már").slug
  end

  # Editing a title must not break the record's public URL.
  def test_updates_leave_the_slug_alone
    post = SmokeTest.posts.create_with_slug(title: "Before")

    assert_equal "before", SmokeTest.posts.update_with_slug(post.id, title: "After").slug
  end

  def test_an_explicit_nil_slug_regenerates
    post = SmokeTest.posts.create_with_slug(title: "Before")

    updated = SmokeTest.posts.update_with_slug(post.id, title: "After", slug: nil)
    assert_equal "after", updated.slug
  end

  def test_the_unique_index_is_what_actually_guarantees_uniqueness
    SmokeTest.posts.create_with_slug(title: "Unique")

    assert_raises(ROM::SQL::UniqueConstraintError) do
      Hanami.app["relations.posts"].changeset(:create, title: "Other", slug: "unique").commit
    end
  end

  # :history and :scoped, against the table and relation that
  # `hanami generate friendly_id` produces. This is the end-to-end proof that the
  # generator's output actually works in a booted app.
  def test_history_resolves_a_retired_slug
    article = SmokeTest.articles.create_with_slug(title: "Before", section_id: 1)
    SmokeTest.articles.update_with_slug(article.id, title: "After", slug: nil)

    assert_equal "after", SmokeTest.articles.friendly_find("after").slug
    assert_equal article.id, SmokeTest.articles.friendly_find("before").id
  end

  def test_history_rows_land_in_the_generated_table
    article = SmokeTest.articles.create_with_slug(title: "Recorded", section_id: 2)

    rows = SmokeTest.slugs.where(sluggable_id: article.id).to_a
    assert_equal ["recorded"], rows.map { |row| row[:slug] }
    assert_equal ["Article"], rows.map { |row| row[:sluggable_type] }
    assert_equal ["section_id:2"], rows.map { |row| row[:scope] }
  end

  def test_scoped_slugs_may_repeat_across_sections
    one = SmokeTest.articles.create_with_slug(title: "Overview", section_id: 1)
    two = SmokeTest.articles.create_with_slug(title: "Overview", section_id: 2)

    assert_equal "overview", one.slug
    assert_equal "overview", two.slug
  end

  def test_delete_with_slug_cleans_up_history
    article = SmokeTest.articles.create_with_slug(title: "Doomed", section_id: 1)
    SmokeTest.articles.delete_with_slug(article.id)

    assert_equal 0, SmokeTest.slugs.count
    assert_nil SmokeTest.articles.friendly_find("doomed")
  end
end
