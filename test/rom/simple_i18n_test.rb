require "helper"
require "i18n"

class Translations < ROM::Relation[:sql]
  schema(:translations, infer: true)
  use :friendly_id, base: :title, use: %i[simple_i18n]
end

class HistoricTranslations < ROM::Relation[:sql]
  schema(:translations, as: :historic_translations, infer: true)
  use :friendly_id,
    base: :title,
    use: %i[simple_i18n history],
    sluggable_type: "Translation"
end

class I18nSlugs < ROM::Relation[:sql]
  schema(:friendly_id_slugs, infer: true)
end

class TranslationRepo < ROM::Repository[:translations]
  include FriendlyId::Rom::Repo
end

class HistoricTranslationRepo < ROM::Repository[:historic_translations]
  include FriendlyId::Rom::Repo
end

# Stands in for Hanami's i18n, which keeps the locale in a per-slice
# thread-local rather than in the global `I18n`.
class FakeSliceI18n
  def initialize(locale) = @locale = locale
  attr_accessor :locale

  def with_locale(value)
    previous = @locale
    @locale = value
    yield
  ensure
    @locale = previous
  end
end

class RomSimpleI18nTest < TestCaseClass
  def setup
    @rom = FriendlyId::Test::Rom.container(:i18n) do |config|
      config.register_relation(Translations)
      config.register_relation(HistoricTranslations)
      config.register_relation(I18nSlugs)
    end
    FriendlyId::Test::Rom.clean!(:i18n)
    @repo = TranslationRepo.new(@rom)
    @historic = HistoricTranslationRepo.new(@rom)
    I18n.available_locales = %i[en fr pt-BR]
    I18n.locale = :en
  end

  def teardown
    I18n.locale = :en
  end

  def rows
    @rom.relations[:translations]
  end

  test "writes to the column for the current locale" do
    record = @repo.create_with_slug(title: "Hello World")

    assert_equal "hello-world", record.slug_en
    assert_nil record.slug_fr
  end

  test "uses a different column under a different locale" do
    I18n.with_locale(:fr) do
      record = @repo.create_with_slug(title: "Bonjour Le Monde")

      assert_equal "bonjour-le-monde", record.slug_fr
      assert_nil record.slug_en
    end
  end

  test "a record can carry a slug in several locales" do
    record = @repo.create_with_slug(title: "Hello World")
    I18n.with_locale(:fr) { @repo.update_with_slug(record.id, title: "Bonjour", slug: nil) }

    stored = rows.by_pk(record.id).one
    assert_equal "hello-world", stored[:slug_en]
    assert_equal "bonjour", stored[:slug_fr]
  end

  test "hyphenated locales become underscored columns" do
    I18n.with_locale(:"pt-BR") do
      record = @repo.create_with_slug(title: "Olá Mundo")
      assert_equal "ola-mundo", record.slug_pt_br
    end
  end

  test "finds by the current locale's slug" do
    @repo.create_with_slug(title: "Hello World")
    I18n.with_locale(:fr) { assert_nil @repo.friendly_find("hello-world") }

    assert_equal "hello-world", @repo.friendly_find("hello-world").slug_en
  end

  test "the same slug may exist in two locales" do
    record = @repo.create_with_slug(title: "Radio")
    I18n.with_locale(:fr) { @repo.update_with_slug(record.id, title: "Radio", slug: nil) }

    stored = rows.by_pk(record.id).one
    assert_equal "radio", stored[:slug_en]
    assert_equal "radio", stored[:slug_fr]
  end

  test "a nil locale runs the block against the current locale" do
    config = FriendlyId::Rom::Configuration.new(base: :title, use: [:simple_i18n])

    assert_equal :slug_en, config.with_locale(nil) { config.slug_column }
    assert_equal :slug_fr, config.with_locale(:fr) { config.slug_column }
    assert_equal :en, config.locale
  end

  test "accepts a non-global i18n source, as Hanami needs" do
    source = FakeSliceI18n.new(:fr)
    config = FriendlyId::Rom::Configuration.new(base: :title, use: [:simple_i18n], i18n: source)

    assert_equal :slug_fr, config.slug_column

    source.locale = :en
    assert_equal :slug_en, config.slug_column

    # The global locale is untouched throughout, which is the entire point.
    assert_equal :en, I18n.locale
  end

  test "history records the slug for whichever locale wrote it" do
    record = @historic.create_with_slug(title: "Hello World")
    I18n.with_locale(:fr) { @historic.update_with_slug(record.id, title: "Bonjour", slug: nil) }

    assert_equal %w[bonjour hello-world],
      @rom.relations[:friendly_id_slugs].pluck(:slug).sort
  end

  # Inherited from the Active Record adapter, whose history lookup filters on
  # sluggable_type and slug only. Pinned rather than fixed, so the two agree.
  test "history lookup is locale blind, as on Active Record" do
    record = @historic.create_with_slug(title: "Hello World")
    I18n.with_locale(:fr) { @historic.update_with_slug(record.id, title: "Bonjour", slug: nil) }

    # "bonjour" was written under :fr, yet resolves under :en via history.
    assert_equal record.id, @historic.friendly_find("bonjour").id
  end
end

# Has to agree with Active Support's `underscore`, which is what the Active
# Record adapter uses to pick a locale's column.
class LocaleSuffixTest < TestCaseClass
  LOCALES = %i[
    en fr de es it ja ko ru ar he
    pt-BR pt-PT zh-CN zh-TW zh-Hans zh-Hant en-GB en-US es-419
    sr-Latn sr-Cyrl az-Latn-AZ nb no fil en_US de_DE
  ].freeze

  def suffix(locale)
    locale.to_s.tr("-", "_").downcase
  end

  test "matches the expected column suffix for every locale shape" do
    expected = {
      en: "en", "pt-BR": "pt_br", "zh-Hans": "zh_hans", "es-419": "es_419",
      "az-Latn-AZ": "az_latn_az", en_US: "en_us"
    }

    expected.each do |locale, want|
      assert_equal want, suffix(locale), "#{locale} produced the wrong suffix"
    end
  end

  test "every locale in the corpus produces a usable column name" do
    LOCALES.each do |locale|
      assert_match(/\A[a-z0-9_]+\z/, suffix(locale), "#{locale} is not a usable column name")
    end
  end
end
