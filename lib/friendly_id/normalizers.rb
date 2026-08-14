module FriendlyId
  # Strategies for turning an arbitrary string into the basis of a slug.
  #
  # These are an alternative to overriding `normalize_friendly_id` in a model,
  # which remains the primary extension point. An override wins over a
  # configured normalizer.
  #
  # A normalizer is only ever used when it is configured; installing babosa
  # does not change how slugs are produced.
  module Normalizers
    # Uses Active Support's `String#parameterize`, which is what
    # `normalize_friendly_id` has always done. This is the default.
    class ActiveSupport
      def call(value, separator: "-")
        value.to_s.parameterize(separator: separator)
      end
    end

    # Uses the babosa gem, which ships transliteration tables for several
    # non-Latin scripts.
    #
    # Opt in with `config.normalizer = FriendlyId::Normalizers::Babosa.new`.
    # Add `gem "babosa"` to your Gemfile first; FriendlyId does not depend on it.
    #
    #     FriendlyId::Normalizers::Babosa.new
    #     #=> "Café del Már"  becomes "cafe-del-mar"
    #     #=> "Крым"          becomes "krym"
    #     #=> "Αθήνα"         becomes "athina"
    #
    #     FriendlyId::Normalizers::Babosa.new(transliterations: [:german])
    #     #=> "Malmö"         becomes "malmoe" rather than "malmo"
    #
    #     FriendlyId::Normalizers::Babosa.new(ascii: false)
    #     #=> "Крым"          becomes "крым"
    #
    # Babosa's transliterators are: bulgarian, cyrillic, danish, german, greek,
    # hindi, latin, macedonian, norwegian, romanian, russian, serbian, spanish,
    # swedish, turkish, ukrainian and vietnamese.
    #
    # Arabic, Persian, Urdu and Hebrew transliterate to an empty string, as they
    # do under `parameterize`, leaving the record with no slug. Override
    # `normalize_friendly_id` to romanise them.
    #
    # Babosa is not a drop-in replacement for `parameterize`: it deletes "." and
    # tab characters where Active Support converts them to the separator, so
    # "3.14159" becomes "314159" rather than "3-14159". Switching an application
    # that already has slugs will change them.
    class Babosa
      # Applied before `:latin`. Each handles characters `:latin` does not know,
      # so they change no Latin result.
      #
      # Language-specific Cyrillic rules such as :ukrainian and :serbian
      # disagree with each other about the same characters, so pass the one you
      # want rather than expecting a default.
      DEFAULT_TRANSLITERATIONS = %i[cyrillic greek vietnamese hindi].freeze

      # @param ascii [Boolean] force the result to ASCII. Defaults to true. Set
      #   to false to keep non-Latin slugs such as "крым" or "北京市".
      # @param transliterations [Array<Symbol>] extra babosa transliterations,
      #   for example `[:german]` or `[:ukrainian]`. These run *first*, so they
      #   win over the defaults for any character they both define.
      def initialize(ascii: true, transliterations: [])
        require "babosa"

        @ascii = ascii

        # The defaults exist to reach ASCII, so a caller asking for non-ASCII
        # gets none of them: `:cyrillic` romanises "Крым" to "krym" before
        # `ascii: false` has any say.
        defaults = @ascii ? DEFAULT_TRANSLITERATIONS : []

        # Babosa applies transliterations in sequence and the first rule to
        # define a character consumes it, so caller rules come first and
        # `:latin` last: `:latin` folds "ö" to "o", which would swallow a
        # request for `:german` and yield "malmo" rather than "malmoe".
        # `:latin` must still be present, because `to_ascii!` strips accents it
        # has not folded, turning "Café" into "caf".
        @transliterations = (Array(transliterations) + defaults + [:latin]).uniq
      rescue LoadError
        raise LoadError, "FriendlyId::Normalizers::Babosa requires the babosa gem. " \
          'Add `gem "babosa"` to your Gemfile.'
      end

      def call(value, separator: "-")
        slug = value.to_s.to_slug
        slug.transliterate!(*@transliterations)
        slug.to_ascii! if @ascii
        slug.normalize!(separator: separator).to_s
      end
    end
  end
end
