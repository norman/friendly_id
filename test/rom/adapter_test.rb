require "helper"

class SequentialPosts < ROM::Relation[:sql]
  schema(:posts, infer: true)
  use :friendly_id, base: :title, use: [:sequentially_slugged]
end

class UuidArticles < ROM::Relation[:sql]
  schema(:articles, infer: true)
  use :friendly_id, base: :title, reserved_words: %w[new edit]
end

class Drafts < ROM::Relation[:sql]
  schema(:drafts, infer: true)
  use :friendly_id, base: :title
end

# The configuration lives in a class-level instance variable, which a subclass
# would not otherwise see.
class InheritedPosts < SequentialPosts
  schema(:posts, as: :inherited_posts, infer: true)
end

class SequentialPostRepo < ROM::Repository[:posts]
  include FriendlyId::Rom::Repo
end

class DraftRepo < ROM::Repository[:drafts]
  include FriendlyId::Rom::Repo
end

class UuidArticleRepo < ROM::Repository[:articles]
  include FriendlyId::Rom::Repo
end

class InheritedPostRepo < ROM::Repository[:inherited_posts]
  include FriendlyId::Rom::Repo
end

class RomAdapterTest < TestCaseClass
  UUID_SUFFIX = /-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/

  def setup
    @rom = FriendlyId::Test::Rom.container(:adapter) do |config|
      config.register_relation(SequentialPosts)
      config.register_relation(UuidArticles)
      config.register_relation(Drafts)
      config.register_relation(InheritedPosts)
    end
    FriendlyId::Test::Rom.clean!(:adapter)
    @posts = SequentialPostRepo.new(@rom)
    @articles = UuidArticleRepo.new(@rom)
    @drafts = DraftRepo.new(@rom)
    @inherited = InheritedPostRepo.new(@rom)
  end

  def posts_relation
    @rom.relations[:posts]
  end

  test "generates a slug on create" do
    assert_equal "hello-world", @posts.create_with_slug(title: "Hello World").slug
  end

  test "normalizes punctuation and accents" do
    assert_equal "cafe-del-mar-2024", @posts.create_with_slug(title: "Café del Már! 2024").slug
  end

  test "finds a record by its slug" do
    @posts.create_with_slug(title: "Hello World")
    assert_equal "Hello World", @posts.friendly_find("hello-world").title
  end

  test "returns nil when no record matches" do
    assert_nil @posts.friendly_find("no-such-slug")
  end

  test "raises when finding with a bang and no record matches" do
    assert_raises(ROM::TupleCountMismatchError) { @posts.friendly_find!("no-such-slug") }
  end

  test "exposes friendly finders on the relation" do
    @posts.create_with_slug(title: "Hello World")
    assert_equal "Hello World", posts_relation.friendly.by_friendly_id("hello-world").one[:title]
  end

  test "reports whether a slug is taken" do
    @posts.create_with_slug(title: "Hello World")
    assert posts_relation.exists_by_friendly_id?("hello-world")
    refute posts_relation.exists_by_friendly_id?("no-such-slug")
  end

  test "appends a sequence when slugs conflict" do
    3.times { @posts.create_with_slug(title: "Hello World") }
    assert_equal %w[hello-world hello-world-2 hello-world-3],
      posts_relation.conflict_slugs("hello-world").sort
  end

  test "appends a uuid when not sequentially slugged" do
    assert_equal "hello-world", @articles.create_with_slug(title: "Hello World").slug
    assert_match UUID_SUFFIX, @articles.create_with_slug(title: "Hello World").slug
  end

  test "treats reserved words as conflicts" do
    assert_match UUID_SUFFIX, @articles.create_with_slug(title: "new").slug
  end

  # Slugs are public URLs, so editing a title must not break every link to the
  # record. As on Active Record, only an explicit `slug: nil` asks for a new one.
  test "leaves the slug alone when the base attribute changes" do
    post = @posts.create_with_slug(title: "Temp Title")
    assert_equal "temp-title", @posts.update_with_slug(post.id, title: "Goodbye World").slug
  end

  test "regenerates from the new base value when the slug is set to nil" do
    post = @posts.create_with_slug(title: "Temp Title")
    updated = @posts.update_with_slug(post.id, title: "Goodbye World", slug: nil)
    assert_equal "goodbye-world", updated.slug
  end

  test "leaves the slug alone when the base attribute is unchanged" do
    post = @posts.create_with_slug(title: "Stable Title")
    assert_equal "stable-title", @posts.update_with_slug(post.id, title: "Stable Title").slug
  end

  # A row written by plain `create` or by a backfill migration has no slug, and
  # should pick one up rather than staying nil forever.
  test "generates a slug for a record that has none" do
    id = @rom.relations[:drafts].insert(title: "Never Slugged")
    assert_equal "never-slugged", @drafts.update_with_slug(id, {}).slug
  end

  # `scope_for_slug_generator` guarantees this on the Active Record side.
  test "regenerates the slug without conflicting with itself" do
    post = @posts.create_with_slug(title: "Some Title")
    assert_equal "some-title", @posts.update_with_slug(post.id, slug: nil).slug
  end

  test "still avoids other records when regenerating" do
    @posts.create_with_slug(title: "Shared Title")
    other = @posts.create_with_slug(title: "Different")
    updated = @posts.update_with_slug(other.id, title: "Shared Title", slug: nil)
    assert_equal "shared-title-2", updated.slug
  end

  test "accepts an explicitly supplied slug" do
    post = @posts.create_with_slug(title: "Some Title")
    assert_equal "chosen-by-hand", @posts.update_with_slug(post.id, slug: "chosen-by-hand").slug
  end

  test "accepts an explicitly supplied slug on create" do
    assert_equal "chosen-by-hand",
      @posts.create_with_slug(title: "Some Title", slug: "chosen-by-hand").slug
  end

  test "an explicit slug is taken as given, not normalized" do
    assert_equal "Not Normalized", @drafts.create_with_slug(title: "x", slug: "Not Normalized").slug
  end

  test "delete_with_slug works without the history addon" do
    post = @posts.create_with_slug(title: "Hello World")
    @posts.delete_with_slug(post.id)

    assert_nil @posts.friendly_find("hello-world")
    assert_equal 0, posts_relation.count
  end

  test "generates a slug without writing anything" do
    assert_equal "some-new-title", @posts.generate_friendly_id(title: "Some New Title")
    assert_equal 0, posts_relation.where(slug: "some-new-title").count
  end

  # Parity with the Active Record adapter, which returns a bare UUID rather
  # than a nil slug when the base cannot be sluggified at all.
  test "falls back to a bare uuid when the base cannot be sluggified" do
    ["!!!", "", "   ", "北京市"].each do |title|
      slug = @articles.create_with_slug(title: title).slug
      assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, slug,
        "expected a bare uuid for #{title.inspect}, got #{slug.inspect}")
    end
  end

  test "accepts string keys as well as symbols" do
    assert_equal "string-keys", @posts.create_with_slug("title" => "String Keys").slug
  end

  test "raises a clear error when the base attribute is missing" do
    error = assert_raises(FriendlyId::ConfigurationError) { @posts.create_with_slug({}) }
    assert_match(/no :title attribute was given/, error.message)
  end

  test "updating a row that does not exist does not blow up" do
    assert_nil @posts.update_with_slug(999_999, title: "Nothing Here")
  end

  test "sequences a base containing LIKE metacharacters" do
    assert_equal "100-pure_gold", @posts.create_with_slug(title: "100% pure_gold").slug
    assert_equal "100-pure_gold-2", @posts.create_with_slug(title: "100% pure_gold").slug
  end

  # Asserted on `conflict_slugs` rather than on the slug, because
  # SequenceCalculator re-filters through its own anchored regexp and discards
  # the stray row anyway. The cost of over-matching is rows read, not a wrong
  # slug, so a test on the slug alone passes with the escaping removed.
  test "escapes LIKE metacharacters in the base when looking for conflicts" do
    @posts.create_with_slug(title: "100% pure_gold")
    @posts.create_with_slug(title: "100% pure_gold")
    posts_relation.changeset(:create, title: "Decoy", slug: "100-pureXgold-9").commit

    # "_" is a single-character wildcard, so unescaped this also returns the
    # decoy, whose "X" sits where the underscore is.
    assert_equal %w[100-pure_gold 100-pure_gold-2],
      posts_relation.conflict_slugs("100-pure_gold").sort
  end

  test "keeps configuration separate per relation" do
    assert SequentialPosts.friendly_id_config.sequential?
    refute UuidArticles.friendly_id_config.sequential?
  end

  test "a subclassed relation inherits its parent's configuration" do
    assert_same SequentialPosts.friendly_id_config, InheritedPosts.friendly_id_config
  end

  test "a subclassed relation still generates slugs" do
    assert_equal "hello-world", @inherited.create_with_slug(title: "Hello World").slug
  end

  test "a subclassed relation shares the parent's addons" do
    @inherited.create_with_slug(title: "Hello World")
    assert_equal "hello-world-2", @inherited.create_with_slug(title: "Hello World").slug
  end
end

class RomConfigurationTest < TestCaseClass
  def relation_using(**options)
    Class.new(ROM::Relation[:sql]) do
      schema(:posts, infer: true)
      use :friendly_id, **options
    end
  end

  test "accepts every supported addon" do
    FriendlyId::Rom::Configuration::SUPPORTED.each do |addon|
      options = {base: :title, use: [addon]}
      options[:scope] = :book_id if addon == :scoped

      FriendlyId::Rom::Configuration.new(options)
    end
  end

  test "supports the same addons as the Active Record adapter" do
    assert_equal %i[finders history reserved scoped sequentially_slugged simple_i18n slugged].sort,
      FriendlyId::Rom::Configuration::SUPPORTED.sort
  end

  test "rejects unknown addons" do
    assert_raises(FriendlyId::UnknownAddonError) { relation_using(base: :title, use: [:bogus]) }
  end

  test "requires a base attribute" do
    assert_raises(FriendlyId::ConfigurationError) { relation_using }
  end

  # NotImplementedError descends from ScriptError, so `rescue => e` would miss
  # it. Every error FriendlyId raises deliberately must be rescuable normally.
  test "all errors are rescuable as StandardError" do
    [FriendlyId::UnsupportedAddonError, FriendlyId::UnknownAddonError, FriendlyId::ConfigurationError].each do |klass|
      assert klass < StandardError, "#{klass} should descend from StandardError"
    end
  end
end
