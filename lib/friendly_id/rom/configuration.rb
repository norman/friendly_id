module FriendlyId
  module Rom
    # Configuration for a ROM relation using FriendlyId.
    #
    # Deliberately separate from {FriendlyId::Configuration}, which is built
    # around including addon modules into an Active Record model class. ROM
    # relations are configured declaratively and slugging happens explicitly in a
    # repository, so the addons here are recorded as flags rather than mixed in.
    class Configuration
      # Addons supported by this adapter, which as of 6.0 is all of them.
      SUPPORTED = %i[
        slugged finders sequentially_slugged reserved history scoped simple_i18n
      ].freeze

      DEFAULT_SLUGS_RELATION = :friendly_id_slugs

      attr_reader :base, :sequence_separator, :slug_limit, :reserved_words,
        :treat_reserved_as_conflict, :treat_numeric_as_conflict, :normalizer,
        :modules, :scope_columns, :slugs_relation, :i18n

      def initialize(options = {})
        @modules = Array(options[:use]).map(&:to_sym)
        validate_modules!

        @base = options.fetch(:base) {
          raise FriendlyId::ConfigurationError, "FriendlyId needs a :base option, e.g. `use :friendly_id, base: :title`"
        }
        @slug_column = (options[:slug_column] || :slug).to_sym
        @sequence_separator = options[:sequence_separator] || "-"
        @slug_limit = options[:slug_limit]
        @reserved_words = options[:reserved_words]
        @treat_reserved_as_conflict = options.fetch(:treat_reserved_as_conflict, true)
        @treat_numeric_as_conflict = options.fetch(:treat_numeric_as_conflict, false)
        @normalizer = options[:normalizer] || FriendlyId::Normalizers::Babosa.new

        @sluggable_type = options[:sluggable_type]
        @slugs_relation = (options[:slugs_relation] || DEFAULT_SLUGS_RELATION).to_sym
        @scope_columns = Array(options[:scope]).map(&:to_sym)
        @i18n = options[:i18n]

        validate_scope!
      end

      def uses?(mod)
        modules.include?(mod.to_sym)
      end

      def sequential?
        uses?(:sequentially_slugged)
      end

      def history?
        uses?(:history)
      end

      def scoped?
        uses?(:scoped)
      end

      def i18n?
        uses?(:simple_i18n)
      end

      # The column slugs are read from and written to.
      #
      # Under `:simple_i18n` this is per-locale, so `slug` becomes `slug_en` or
      # `slug_pt_br` depending on the current locale, and it therefore has to be
      # asked for at call time rather than cached.
      def slug_column
        return @slug_column unless i18n?

        :"#{@slug_column}_#{locale_suffix}"
      end

      # The column FriendlyId queries when finding by friendly id.
      def query_field
        slug_column
      end

      # The value written to `friendly_id_slugs.sluggable_type`.
      #
      # Active Record uses the model's `base_class.to_s`, e.g. "Post". ROM has no
      # model class, so this defaults to the relation's name, e.g. "posts". Set
      # it explicitly to share a slugs table with an Active Record application:
      #
      #     use :friendly_id, base: :title, use: [:history], sluggable_type: "Post"
      def sluggable_type_for(relation)
        @sluggable_type || relation.schema.name.to_sym.to_s
      end

      # The object asked for the current locale. Defaults to the `I18n` module.
      #
      # Hanami's i18n is deliberately not the global `I18n`: each slice keeps its
      # locale in a thread-local, so a library reading `I18n.locale` silently sees
      # the default locale forever. Hanami users pass `i18n: Hanami.app["i18n"]`.
      # Both objects answer `locale` and `with_locale`, so nothing else differs.
      def i18n_source
        @i18n || default_i18n
      end

      def locale
        i18n_source.locale
      end

      def with_locale(value, &block)
        return yield if value.nil?

        i18n_source.with_locale(value, &block)
      end

      private

      def default_i18n
        defined?(::I18n) ? ::I18n : raise(FriendlyId::ConfigurationError,
          "FriendlyId's :simple_i18n addon needs an i18n source. Require the i18n gem, " \
          'or pass one explicitly, e.g. `i18n: Hanami.app["i18n"]`.')
      end

      # Mirrors Active Support's `underscore` for locale names: `:"pt-BR"` becomes
      # "pt_br". Verified equal to `underscore` across every locale shape by
      # LocaleSuffixTest in test/rom/simple_i18n_test.rb.
      def locale_suffix
        locale.to_s.tr("-", "_").downcase
      end

      def validate_modules!
        modules.each do |mod|
          unless SUPPORTED.include?(mod)
            raise FriendlyId::UnknownAddonError, "Unknown FriendlyId addon :#{mod}. " \
              "Supported addons are: #{SUPPORTED.map { |m| ":#{m}" }.join(", ")}."
          end
        end
      end

      def validate_scope!
        if scoped? && scope_columns.empty?
          raise FriendlyId::ConfigurationError,
            "FriendlyId's :scoped addon needs a :scope option naming one or more columns, " \
            "e.g. `use :friendly_id, base: :title, use: [:scoped], scope: :author_id`. " \
            "Unlike Active Record this takes the column itself, not an association name."
        end

        if scope_columns.any? && !scoped?
          raise FriendlyId::ConfigurationError,
            "A :scope option was given without the :scoped addon. Add `use: [:scoped]`."
        end
      end
    end
  end
end
