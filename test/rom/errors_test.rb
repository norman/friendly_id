require "helper"

# The messages are the adapter's user interface when an application is wired up
# wrong, so they are asserted rather than just the exception class.

class UnconfiguredDrafts < ROM::Relation[:sql]
  schema(:drafts, as: :unconfigured_drafts, infer: true)
end

class OrphanHistoryPosts < ROM::Relation[:sql]
  schema(:posts, as: :orphan_history_posts, infer: true)
  use :friendly_id, base: :title, use: %i[history], sluggable_type: "Post"
end

# Renamed, so the message has something other than the default to report.
class RenamedSlugsPosts < ROM::Relation[:sql]
  schema(:posts, as: :renamed_slugs_posts, infer: true)
  use :friendly_id, base: :title, use: %i[history], slugs_relation: :my_slugs
end

class PlainPosts < ROM::Relation[:sql]
  schema(:posts, as: :plain_posts, infer: true)
  use :friendly_id, base: :title
end

class RootlessRepo < ROM::Repository
  include FriendlyId::Rom::Repo
end

class UnconfiguredDraftRepo < ROM::Repository[:unconfigured_drafts]
  include FriendlyId::Rom::Repo
end

class OrphanHistoryPostRepo < ROM::Repository[:orphan_history_posts]
  include FriendlyId::Rom::Repo
end

class RomErrorsTest < TestCaseClass
  def setup
    # No slugs relation is registered, which is what OrphanHistoryPosts needs.
    @rom = FriendlyId::Test::Rom.container(:errors) do |config|
      config.register_relation(UnconfiguredDrafts)
      config.register_relation(OrphanHistoryPosts)
      config.register_relation(RenamedSlugsPosts)
      config.register_relation(PlainPosts)
    end
    FriendlyId::Test::Rom.clean!(:errors)
  end

  test "a repository with no root relation says how to declare one" do
    error = assert_raises(FriendlyId::ConfigurationError) do
      RootlessRepo.new(@rom).create_with_slug(title: "Hello World")
    end

    assert_match(/RootlessRepo has no root relation/, error.message)
    assert_match(/ROM::Repository\[:posts\]/, error.message)
    assert_match(/pass the relation as the last argument/, error.message)
  end

  test "a repository with no root relation works when handed one" do
    relation = @rom.relations[:plain_posts]

    assert_equal "hello-world",
      RootlessRepo.new(@rom).generate_friendly_id({title: "Hello World"}, relation)
  end

  test "a relation without the plugin says to add it" do
    error = assert_raises(FriendlyId::ConfigurationError) do
      UnconfiguredDraftRepo.new(@rom).create_with_slug(title: "Hello World")
    end

    assert_match(/is not configured for FriendlyId/, error.message)
    assert_match(/use :friendly_id, base: :some_column/, error.message)
  end

  test "history without a slugs relation names the generator that makes one" do
    error = assert_raises(FriendlyId::ConfigurationError) do
      OrphanHistoryPostRepo.new(@rom).create_with_slug(title: "Hello World")
    end

    assert_match(/:history addon needs a :friendly_id_slugs relation/, error.message)
    assert_match(/hanami generate friendly_id/, error.message)
    assert_match(/schema\(:friendly_id_slugs, infer: true\)/, error.message)
  end

  test "the missing slugs relation message uses the configured name" do
    error = assert_raises(FriendlyId::ConfigurationError) do
      RootlessRepo.new(@rom).create_with_slug({title: "Hello World"}, @rom.relations[:renamed_slugs_posts])
    end

    assert_match(/needs a :my_slugs relation/, error.message)
    assert_match(/schema\(:my_slugs, infer: true\)/, error.message)
  end

  test "simple_i18n without an i18n source says how to supply one" do
    without_i18n do
      config = FriendlyId::Rom::Configuration.new(base: :title, use: %i[simple_i18n])
      error = assert_raises(FriendlyId::ConfigurationError) { config.slug_column }

      assert_match(/:simple_i18n addon needs an i18n source/, error.message)
      assert_match(/Hanami\.app\["i18n"\]/, error.message)
    end
  end

  # Lazy, so an application with no i18n gem at all still works.
  test "an i18n source is only needed once a locale is asked for" do
    without_i18n do
      FriendlyId::Rom::Configuration.new(base: :title, use: %i[slugged])
    end
  end

  private

  # `defined?(::I18n)` is the check under test and the ROM bundle loads i18n,
  # so the constant has to go away for the duration.
  def without_i18n
    return yield unless defined?(::I18n)

    i18n = Object.send(:remove_const, :I18n)
    begin
      yield
    ensure
      Object.const_set(:I18n, i18n)
    end
  end
end
