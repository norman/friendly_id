require "helper"

class HistoricPosts < ROM::Relation[:sql]
  schema(:posts, as: :historic_posts, infer: true)
  use :friendly_id, base: :title, use: %i[history], sluggable_type: "Post"
end

# Shares the slugs table with HistoricPosts, so sluggable_type has to keep them apart.
class HistoricArticles < ROM::Relation[:sql]
  schema(:articles, as: :historic_articles, infer: true)
  use :friendly_id, base: :title, use: %i[history], sluggable_type: "Article"
end

class SequentialHistoricDrafts < ROM::Relation[:sql]
  schema(:drafts, as: :historic_drafts, infer: true)
  use :friendly_id, base: :title, use: %i[history sequentially_slugged], sluggable_type: "Draft"
end

class FriendlyIdSlugs < ROM::Relation[:sql]
  schema(:friendly_id_slugs, infer: true)
end

# Deliberately without :history, to prove the slugs table is left alone.
class PlainChapters < ROM::Relation[:sql]
  schema(:chapters, infer: true)
  use :friendly_id, base: :title
end

class PlainChapterRepo < ROM::Repository[:chapters]
  include FriendlyId::Rom::Repo
end

class HistoricPostRepo < ROM::Repository[:historic_posts]
  include FriendlyId::Rom::Repo
end

class HistoricArticleRepo < ROM::Repository[:historic_articles]
  include FriendlyId::Rom::Repo
end

class SequentialHistoricDraftRepo < ROM::Repository[:historic_drafts]
  include FriendlyId::Rom::Repo
end

class RomHistoryTest < TestCaseClass
  def setup
    @rom = FriendlyId::Test::Rom.container(:history) do |config|
      config.register_relation(HistoricPosts)
      config.register_relation(HistoricArticles)
      config.register_relation(SequentialHistoricDrafts)
      config.register_relation(FriendlyIdSlugs)
      config.register_relation(PlainChapters)
    end
    FriendlyId::Test::Rom.clean!(:history)
    @posts = HistoricPostRepo.new(@rom)
    @articles = HistoricArticleRepo.new(@rom)
    @drafts = SequentialHistoricDraftRepo.new(@rom)
  end

  def slugs
    @rom.relations[:friendly_id_slugs]
  end

  def rename(post, title)
    @posts.update_with_slug(post.id, title: title, slug: nil)
  end

  test "records a slug on create" do
    post = @posts.create_with_slug(title: "Hello World")
    assert_equal [["hello-world", "Post", post.id]],
      slugs.pluck(:slug, :sluggable_type, :sluggable_id)
  end

  test "does not record a duplicate row when nothing changed" do
    post = @posts.create_with_slug(title: "Hello World")
    @posts.update_with_slug(post.id, title: "Hello World")
    assert_equal 1, slugs.count
  end

  test "finds a record by a retired slug" do
    post = @posts.create_with_slug(title: "Hello World")
    rename(post, "Goodbye World")

    assert_equal "goodbye-world", @posts.friendly_find("goodbye-world").slug
    assert_equal post.id, @posts.friendly_find("hello-world").id
  end

  test "finds through several generations of slug" do
    post = @posts.create_with_slug(title: "One")
    rename(post, "Two")
    rename(post, "Three")

    %w[one two three].each do |slug|
      assert_equal post.id, @posts.friendly_find(slug).id, "#{slug} did not resolve"
    end
  end

  test "the bang finder raises for a slug that never existed" do
    assert_raises(ROM::TupleCountMismatchError) { @posts.friendly_find!("never") }
  end

  test "returns nil for a slug that was never used" do
    @posts.create_with_slug(title: "Hello World")

    assert_nil @posts.friendly_find("never-existed")
  end

  test "the bang finder resolves a retired slug" do
    post = @posts.create_with_slug(title: "Hello World")
    rename(post, "Goodbye World")

    assert_equal post.id, @posts.friendly_find!("hello-world").id
  end

  # Otherwise a new record steals the slug and the redirect :history exists for breaks.
  test "a retired slug is not available to another record" do
    post = @posts.create_with_slug(title: "Hello World")
    rename(post, "Goodbye World")

    other = @posts.create_with_slug(title: "Hello World")
    refute_equal "hello-world", other.slug
    assert_equal post.id, @posts.friendly_find("hello-world").id
  end

  test "sequence numbers account for retired slugs" do
    draft = @drafts.create_with_slug(title: "Shared")
    @drafts.update_with_slug(draft.id, title: "Renamed", slug: nil)

    assert_equal "shared-2", @drafts.create_with_slug(title: "Shared").slug
  end

  test "a record can revert to a slug it used before" do
    post = @posts.create_with_slug(title: "Hello World")
    rename(post, "Goodbye World")
    reverted = rename(post, "Hello World")

    assert_equal "hello-world", reverted.slug
    assert_equal 1, slugs.where(slug: "hello-world").count
  end

  test "sluggable_type keeps two relations sharing the table apart" do
    post = @posts.create_with_slug(title: "Shared Title")
    article = @articles.create_with_slug(title: "Shared Title")

    assert_equal "shared-title", post.slug
    assert_equal "shared-title", article.slug
    assert_equal post.id, @posts.friendly_find("shared-title").id
    assert_equal article.id, @articles.friendly_find("shared-title").id
  end

  test "delete_with_slug removes the history rows" do
    post = @posts.create_with_slug(title: "Hello World")
    rename(post, "Goodbye World")
    assert_equal 2, slugs.count

    @posts.delete_with_slug(post.id)

    assert_equal 0, slugs.count
    assert_nil @posts.friendly_find("hello-world")
  end

  test "delete_with_slug leaves another relation's rows alone" do
    post = @posts.create_with_slug(title: "A Post")
    @articles.create_with_slug(title: "An Article")

    @posts.delete_with_slug(post.id)

    assert_equal ["Article"], slugs.pluck(:sluggable_type)
  end

  test "records the slug for a row that had none" do
    id = @rom.relations[:historic_drafts].insert(title: "Never Slugged")
    @drafts.update_with_slug(id, {})

    assert_equal ["never-slugged"], slugs.where(sluggable_type: "Draft").pluck(:slug)
  end

  # Or a failure leaves a slug row pointing at nothing.
  test "the history row is written in the same transaction as the record" do
    @posts.create_with_slug(title: "Hello World")

    assert_raises(ROM::SQL::UniqueConstraintError) do
      @posts.create_with_slug(title: "Second", slug: "hello-world")
    end

    assert_equal 1, slugs.count
    assert_equal 1, @rom.relations[:historic_posts].count
  end

  test "a relation without :history writes nothing to the slugs table" do
    plain = PlainChapterRepo.new(@rom)
    plain.create_with_slug(title: "No History Here", book_id: 1)

    assert_equal 0, slugs.count
  end

  test "a retired slug containing LIKE metacharacters still conflicts" do
    draft = @drafts.create_with_slug(title: "100% pure_gold")
    assert_equal "100-pure_gold", draft.slug
    @drafts.update_with_slug(draft.id, title: "Renamed", slug: nil)

    assert_equal "100-pure_gold-2", @drafts.create_with_slug(title: "100% pure_gold").slug
  end

  # SlugScope builds its own LIKE prefix rather than reusing the relation's, so
  # the escaping has to be proven twice. Asserted on `conflict_slugs` for the
  # reason given in adapter_test.rb.
  test "escapes LIKE metacharacters when searching the slugs table" do
    draft = @drafts.create_with_slug(title: "Anything")
    @drafts.update_with_slug(draft.id, slug: "100-off-9")

    scope = FriendlyId::Rom::SlugScope.new(
      @rom.relations[:historic_drafts],
      SequentialHistoricDrafts.friendly_id_config,
      slugs: slugs,
      sluggable_type: "Draft"
    )

    # "%" matches any run of characters, so unescaped this returns "100-off-9".
    assert_equal [], scope.conflict_slugs("100%off")
    assert_equal ["100-off-9"], scope.conflict_slugs("100-off")
  end
end
