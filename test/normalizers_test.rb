require "helper"

begin
  require "babosa"
rescue LoadError
  # Babosa is an optional development dependency.
end

# Pins each normalizer's output against a fixed corpus.
class NormalizersTest < TestCaseClass
  include FriendlyId::Test

  # Latin-script inputs, where the two normalizers are expected to agree.
  SHARED = {
    "Hello World" => "hello-world",
    "hello" => "hello",
    "a b c" => "a-b-c",
    "Café del Már" => "cafe-del-mar",
    "Ærøskøbing" => "aeroskobing",
    "Straße" => "strasse",
    "Þórshöfn" => "thorshofn",
    "Łódź" => "lodz",
    "Œuvre" => "oeuvre",
    "Señor Muñoz" => "senor-munoz",
    "naïve" => "naive",
    "Zoë" => "zoe",
    "Ångström" => "angstrom",
    "über-cool" => "uber-cool",
    "Ĳsselmeer" => "ijsselmeer",
    "ñ" => "n",
    "100% pure" => "100-pure",
    "foo_bar" => "foo_bar",
    "foo--bar" => "foo-bar",
    "-leading" => "leading",
    "trailing-" => "trailing",
    "MiXeD CaSe" => "mixed-case",
    "12345" => "12345",
    "!!!" => "",
    "" => ""
  }.freeze

  # Babosa deletes "." and tab where Active Support turns them into the
  # separator.
  DIVERGENT = {
    "3.14159" => {active_support: "3-14159", babosa: "314159"},
    "Ruby on Rails 8.1" => {active_support: "ruby-on-rails-8-1", babosa: "ruby-on-rails-81"},
    "tab\there" => {active_support: "tab-here", babosa: "tabhere"}
  }.freeze

  def active_support
    FriendlyId::Normalizers::ActiveSupport.new
  end

  def babosa
    FriendlyId::Normalizers::Babosa.new
  end

  test "the Active Support normalizer matches String#parameterize" do
    SHARED.each_key do |input|
      assert_equal input.parameterize, active_support.call(input), "for #{input.inspect}"
    end
  end

  test "the Active Support normalizer produces the expected slugs" do
    SHARED.each do |input, expected|
      assert_equal expected, active_support.call(input), "for #{input.inspect}"
    end
  end

  test "the Active Support normalizer honours the separator" do
    assert_equal "hello_world", active_support.call("Hello World", separator: "_")
  end

  if defined?(Babosa)
    test "the babosa normalizer agrees on Latin-script input" do
      SHARED.each do |input, expected|
        assert_equal expected, babosa.call(input), "for #{input.inspect}"
      end
    end

    test "the babosa normalizer honours the separator" do
      assert_equal "hello_world", babosa.call("Hello World", separator: "_")
    end

    test "the normalizers differ only where documented" do
      DIVERGENT.each do |input, expected|
        assert_equal expected[:active_support], active_support.call(input), "AS for #{input.inspect}"
        assert_equal expected[:babosa], babosa.call(input), "babosa for #{input.inspect}"
      end
    end

    # Active Support's table is Latin only: it discards Cyrillic and Greek
    # entirely, and mangles Vietnamese because I18n has no entry for "ẵ".
    test "babosa handles scripts Active Support cannot" do
      {
        "Крым" => {transliterations: [:russian], expected: "krym", active_support: ""},
        "Москва" => {transliterations: [:russian], expected: "moskva", active_support: ""},
        "Αθήνα" => {transliterations: [:greek], expected: "athina", active_support: ""},
        "Đà Nẵng" => {transliterations: [:vietnamese], expected: "da-nang", active_support: "da-n-ng"}
      }.each do |input, options|
        normalizer = FriendlyId::Normalizers::Babosa.new(transliterations: options[:transliterations])
        assert_equal options[:expected], normalizer.call(input), "for #{input.inspect}"
        assert_equal options[:active_support], input.parameterize,
          "Active Support's output for #{input.inspect} changed"
      end
    end

    # The defaults exist to reach ASCII, so asking for non-ASCII switches them
    # off. Otherwise :cyrillic romanises the string the caller asked to keep.
    test "babosa can keep non-ASCII slugs when asked" do
      normalizer = FriendlyId::Normalizers::Babosa.new(ascii: false)
      assert_equal "крым", normalizer.call("Крым")
      assert_equal "北京市", normalizer.call("北京市")
      assert_equal "αθήνα", normalizer.call("Αθήνα")
    end

    test "an explicit transliteration still applies when keeping non-ASCII" do
      normalizer = FriendlyId::Normalizers::Babosa.new(ascii: false, transliterations: [:russian])
      assert_equal "krym", normalizer.call("Крым")
    end

    # Omitting :latin makes to_ascii! strip accents instead of folding them.
    test "babosa folds accents even with other transliterations requested" do
      normalizer = FriendlyId::Normalizers::Babosa.new(transliterations: [:russian])
      assert_equal "cafe-del-mar", normalizer.call("Café del Már")
    end

    # Without these, each of these inputs produces an empty string, and so a
    # record with no slug.
    test "babosa covers Cyrillic, Greek, Vietnamese and Devanagari by default" do
      normalizer = FriendlyId::Normalizers::Babosa.new

      assert_equal "krym", normalizer.call("Крым")
      assert_equal "moskva", normalizer.call("Москва")
      assert_equal "athina", normalizer.call("Αθήνα")
      assert_equal "ha-noi", normalizer.call("Hà Nội")
      assert_equal "nmste", normalizer.call("नमस्ते")
    end

    # Every default covers characters :latin does not define, so none may alter
    # a Latin result.
    test "the wider default changes no Latin-script result" do
      wide = FriendlyId::Normalizers::Babosa.new
      narrow = ->(value) {
        slug = value.to_s.to_slug
        slug.transliterate!(:latin)
        slug.to_ascii!
        slug.normalize!.to_s
      }

      SHARED.each_key do |input|
        assert_equal narrow.call(input), wide.call(input), "for #{input.inspect}"
      end
    end

    # Babosa applies rules in sequence and the first to define a character
    # consumes it, so caller rules run before :latin.
    test "a requested transliteration wins over the defaults" do
      assert_equal "malmoe", FriendlyId::Normalizers::Babosa.new(transliterations: [:german]).call("Malmö")
      assert_equal "malmo", FriendlyId::Normalizers::Babosa.new.call("Malmö")
    end

    test "a language-specific Cyrillic rule wins over the generic one" do
      assert_equal "pryvit", FriendlyId::Normalizers::Babosa.new(transliterations: [:ukrainian]).call("Привіт")
      assert_equal "privt", FriendlyId::Normalizers::Babosa.new.call("Привіт")
    end

    # Neither library covers these. See
    # https://github.com/norman/friendly_id/issues/1015
    test "right-to-left scripts are not transliterated by either normalizer" do
      {"مرحبا" => "Arabic", "سلام" => "Persian", "שלום" => "Hebrew"}.each do |input, script|
        assert_equal "", FriendlyId::Normalizers::Babosa.new.call(input), "babosa, #{script}"
        assert_equal "", input.parameterize, "Active Support, #{script}"
      end
    end
  end
end

class SluggedNormalizerTest < TestCaseClass
  include FriendlyId::Test

  UPCASED = Class.new do
    def call(value, separator: "-")
      value.to_s.upcase.gsub(/[^A-Z0-9]+/, separator).gsub(/\A#{separator}|#{separator}\z/, "")
    end
  end

  def model_class(**options, &block)
    Class.new(ActiveRecord::Base) do
      self.table_name = "journalists"
      extend FriendlyId

      friendly_id :name, use: :slugged, **options
      class_eval(&block) if block
      def self.name
        "Journalist"
      end
    end
  end

  test "the default normalizer is the Active Support one" do
    assert_instance_of FriendlyId::Normalizers::ActiveSupport,
      model_class.friendly_id_config.normalizer
  end

  test "a model's normalized text is byte-identical to String#parameterize" do
    record = model_class.new
    corpus = NormalizersTest::SHARED.keys + NormalizersTest::DIVERGENT.keys

    corpus.each do |input|
      assert_equal input.parameterize, record.normalize_friendly_id(input),
        "#{input.inspect} did not match parameterize"
    end
  end

  test "a configured normalizer is used" do
    klass = model_class { friendly_id_config.normalizer = UPCASED.new }

    with_instance_of(klass, name: "Hello World") do |record|
      assert_equal "HELLO-WORLD", record.slug
    end
  end

  test "overriding normalize_friendly_id wins over a configured normalizer" do
    klass = model_class do
      friendly_id_config.normalizer = UPCASED.new

      def normalize_friendly_id(value)
        "overridden"
      end
    end

    with_instance_of(klass, name: "Hello World") { |record| assert_equal "overridden", record.slug }
  end

  test "calling super from an override still reaches the normalizer" do
    klass = model_class do
      friendly_id_config.normalizer = UPCASED.new

      def normalize_friendly_id(value)
        super.tr("-", "_")
      end
    end

    with_instance_of(klass, name: "Hello World") { |record| assert_equal "HELLO_WORLD", record.slug }
  end

  test "slug_limit still applies to a custom normalizer's output" do
    klass = model_class(slug_limit: 5) { friendly_id_config.normalizer = UPCASED.new }

    with_instance_of(klass, name: "Hello World") { |record| assert_equal "HELLO", record.slug }
  end

  # Babosa is loadable here, and would give "ruby-on-rails-81" for this input.
  test "babosa is not used merely because it is installed" do
    skip "babosa is not installed" unless defined?(::Babosa)

    with_instance_of(model_class, name: "Ruby on Rails 8.1") do |record|
      assert_equal "ruby-on-rails-8-1", record.slug
    end
  end

  # It separates a slug from its sequence, not the words within one.
  test "sequence_separator does not become the word separator" do
    klass = model_class(use: %i[slugged sequentially_slugged], sequence_separator: ":")

    with_instance_of(klass, name: "Hello World") do |record|
      assert_equal "hello-world", record.slug
      assert_equal "hello-world:2", klass.create!(name: "Hello World").slug
    end
  end
end
