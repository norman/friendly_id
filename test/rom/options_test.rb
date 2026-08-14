require "helper"

# Configuration options the other ROM test files never set.

# `articles` has no unique index, so the UUID path is reachable.
class LimitedArticles < ROM::Relation[:sql]
  schema(:articles, as: :limited_articles, infer: true)
  use :friendly_id, base: :title, slug_limit: 45
end

class TinyLimitDrafts < ROM::Relation[:sql]
  schema(:drafts, as: :tiny_limit_drafts, infer: true)
  use :friendly_id, base: :title, slug_limit: 5
end

class ColonSequencedPosts < ROM::Relation[:sql]
  schema(:posts, as: :colon_sequenced_posts, infer: true)
  use :friendly_id, base: :title, use: %i[sequentially_slugged], sequence_separator: ":"
end

class NumericArticles < ROM::Relation[:sql]
  schema(:articles, as: :numeric_articles, infer: true)
  use :friendly_id, base: :title, treat_numeric_as_conflict: true
end

class PermissiveArticles < ROM::Relation[:sql]
  schema(:articles, as: :permissive_articles, infer: true)
  use :friendly_id, base: :title, reserved_words: %w[new edit], treat_reserved_as_conflict: false
end

class UpcasingNormalizer
  def call(value, separator: "-")
    value.to_s.upcase.gsub(/[^A-Z0-9]+/, separator).gsub(/\A-|-\z/, "")
  end
end

class UpcasedDrafts < ROM::Relation[:sql]
  schema(:drafts, as: :upcased_drafts, infer: true)
  use :friendly_id, base: :title, normalizer: UpcasingNormalizer.new
end

class CustomTableDrafts < ROM::Relation[:sql]
  schema(:drafts, as: :custom_table_drafts, infer: true)
  use :friendly_id,
    base: :title,
    use: %i[history],
    slugs_relation: :custom_slugs,
    sluggable_type: "Draft"
end

class CustomSlugs < ROM::Relation[:sql]
  schema(:custom_slugs, infer: true)
end

class OptionsSlugs < ROM::Relation[:sql]
  schema(:friendly_id_slugs, infer: true)
end

class LimitedArticleRepo < ROM::Repository[:limited_articles]
  include FriendlyId::Rom::Repo
end

class TinyLimitDraftRepo < ROM::Repository[:tiny_limit_drafts]
  include FriendlyId::Rom::Repo
end

class ColonSequencedPostRepo < ROM::Repository[:colon_sequenced_posts]
  include FriendlyId::Rom::Repo
end

class NumericArticleRepo < ROM::Repository[:numeric_articles]
  include FriendlyId::Rom::Repo
end

class PermissiveArticleRepo < ROM::Repository[:permissive_articles]
  include FriendlyId::Rom::Repo
end

class UpcasedDraftRepo < ROM::Repository[:upcased_drafts]
  include FriendlyId::Rom::Repo
end

class CustomTableDraftRepo < ROM::Repository[:custom_table_drafts]
  include FriendlyId::Rom::Repo
end

class RomOptionsTest < TestCaseClass
  UUID = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

  def setup
    @rom = FriendlyId::Test::Rom.container(:options) do |config|
      [LimitedArticles, TinyLimitDrafts, ColonSequencedPosts, NumericArticles,
        PermissiveArticles, UpcasedDrafts, CustomTableDrafts, CustomSlugs,
        OptionsSlugs].each { |relation| config.register_relation(relation) }
    end
    FriendlyId::Test::Rom.clean!(:options)
  end

  test "slug_limit truncates the generated slug" do
    assert_equal "hello", TinyLimitDraftRepo.new(@rom).create_with_slug(title: "Hello World").slug
  end

  # The candidate is shortened to leave room, or the limit is exceeded by
  # exactly the length of the suffix.
  test "slug_limit leaves room for a uuid suffix" do
    repo = LimitedArticleRepo.new(@rom)
    repo.create_with_slug(title: "Hello World")
    slug = repo.create_with_slug(title: "Hello World").slug

    assert_equal 45, slug.length
    assert_match(/\Ahello-wo-#{UUID}\z/o, slug)
  end

  test "slug_limit applies to a title longer than the limit" do
    slug = LimitedArticleRepo.new(@rom).create_with_slug(title: "A" * 100).slug
    assert_equal 45, slug.length
  end

  test "sequence_separator joins the sequence" do
    repo = ColonSequencedPostRepo.new(@rom)
    repo.create_with_slug(title: "Hello World")

    assert_equal "hello-world:2", repo.create_with_slug(title: "Hello World").slug
  end

  # It separates a slug from its sequence, not the words within one. Passing it
  # to the normalizer would give "hello:world" and disagree with Active Record.
  test "sequence_separator is not the word separator" do
    assert_equal "hello-world", ColonSequencedPostRepo.new(@rom).create_with_slug(title: "Hello World").slug
  end

  test "treat_numeric_as_conflict sends a purely numeric slug to a uuid" do
    assert_match(/\A12345-#{UUID}\z/o, NumericArticleRepo.new(@rom).create_with_slug(title: "12345").slug)
  end

  # The same hole fixed on the Active Record side in 5.7.
  test "treat_numeric_as_conflict catches leading zeros" do
    assert_match(/\A007-#{UUID}\z/o, NumericArticleRepo.new(@rom).create_with_slug(title: "007").slug)
  end

  test "treat_numeric_as_conflict leaves alphanumeric slugs alone" do
    assert_equal "product-123", NumericArticleRepo.new(@rom).create_with_slug(title: "Product 123").slug
  end

  test "numeric slugs are allowed by default" do
    assert_equal "12345", LimitedArticleRepo.new(@rom).create_with_slug(title: "12345").slug
  end

  # The Active Record adapter raises a validation error instead. ROM has no
  # validations, so the reserved word is simply used.
  test "treat_reserved_as_conflict false lets a reserved word through" do
    assert_equal "new", PermissiveArticleRepo.new(@rom).create_with_slug(title: "new").slug
  end

  test "a configured normalizer is used" do
    assert_equal "HELLO-WORLD", UpcasedDraftRepo.new(@rom).create_with_slug(title: "Hello World").slug
  end

  test "the default normalizer is babosa" do
    assert_instance_of FriendlyId::Normalizers::Babosa, TinyLimitDrafts.friendly_id_config.normalizer
  end

  test "history writes to the configured slugs relation" do
    repo = CustomTableDraftRepo.new(@rom)
    draft = repo.create_with_slug(title: "Hello World")

    assert_equal [["hello-world", draft.id]],
      @rom.relations[:custom_slugs].pluck(:slug, :sluggable_id)
    assert_equal 0, @rom.relations[:friendly_id_slugs].count
  end

  test "history reads back from the configured slugs relation" do
    repo = CustomTableDraftRepo.new(@rom)
    draft = repo.create_with_slug(title: "Hello World")
    repo.update_with_slug(draft.id, title: "Goodbye World", slug: nil)

    assert_equal draft.id, repo.friendly_find("hello-world").id
  end

  test "delete_with_slug clears the configured slugs relation" do
    repo = CustomTableDraftRepo.new(@rom)
    draft = repo.create_with_slug(title: "Hello World")
    repo.delete_with_slug(draft.id)

    assert_equal 0, @rom.relations[:custom_slugs].count
  end
end
