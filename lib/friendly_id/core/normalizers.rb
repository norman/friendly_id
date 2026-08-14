module FriendlyId
  # Strategies for turning an arbitrary string into the basis of a slug.
  #
  # These are an alternative to overriding `normalize_friendly_id` in a model,
  # which remains the primary and fully supported extension point. A model that
  # overrides `normalize_friendly_id` always wins over a configured normalizer.
  #
  # Normalizers are always selected explicitly. FriendlyId never picks one based
  # on which gems happen to be installed, because that would let a change in the
  # bundle silently rewrite an application's URLs.
  module Normalizers
    # Uses Active Support's `String#parameterize`.
    #
    # This is what the Active Record adapter has always used and what it
    # continues to use unconditionally, so that upgrading FriendlyId never
    # changes an existing slug.
    class ActiveSupport
      def call(value, separator: "-")
        value.to_s.parameterize(separator: separator)
      end
    end

    # Uses the babosa gem, which unlike Active Support has no dependencies of its
    # own and ships transliteration tables for several non-Latin scripts.
    #
    # This is the default for adapters that cannot assume Active Support is
    # present, such as the ROM adapter used by Hanami.
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
    # ### What is and is not covered
    #
    # Babosa's transliterators are: bulgarian, cyrillic, danish, german, greek,
    # hindi, latin, macedonian, norwegian, romanian, russian, serbian, spanish,
    # swedish, turkish, ukrainian and vietnamese.
    #
    # **There is no Arabic, Persian, Urdu or Hebrew.** Those scripts transliterate
    # to an empty string here, exactly as they do under `parameterize`, and the
    # adapter then falls back to a UUID. Neither library romanises right-to-left
    # scripts, and FriendlyId does not attempt to ship tables for them. If you
    # need one, supply your own by overriding `normalize_friendly_id`.
    #
    # Note also that babosa is *not* a drop-in replacement for `parameterize`. It
    # deletes "." and tab characters where Active Support converts them to the
    # separator, so "3.14159" becomes "314159" rather than "3-14159". Do not
    # switch an existing application to it without accepting that its slugs will
    # change.
    class Babosa
      # Applied before `:latin` so that broad script coverage is available
      # without configuration. Each of these handles characters `:latin` does not
      # know, so adding them changes no Latin result. Measured against a Latin
      # corpus in test/normalizers_test.rb.
      #
      # Language-specific Cyrillic rules such as :ukrainian and :serbian are
      # deliberately absent: they disagree with each other about the same
      # characters, so only the application knows which it wants.
      DEFAULT_TRANSLITERATIONS = %i[cyrillic greek vietnamese hindi].freeze

      # @param ascii [Boolean] force the result to ASCII. Defaults to true, which
      #   matches what Rails applications expect. Set to false to keep non-Latin
      #   slugs such as "крым" or "北京市", which are legal in modern URLs and
      #   which `parameterize` cannot produce at all.
      # @param transliterations [Array<Symbol>] extra babosa transliterations,
      #   for example `[:german]` or `[:ukrainian]`. These run *first*, so they
      #   win over the defaults for any character they both define.
      def initialize(ascii: true, transliterations: [])
        require "babosa"

        @ascii = ascii

        # The defaults exist to reach ASCII, so a caller who wants non-ASCII gets
        # none of them: `:cyrillic` would romanise "Крым" to "krym" before
        # `ascii: false` had any say.
        defaults = @ascii ? DEFAULT_TRANSLITERATIONS : []

        # Order decides which rule wins, and losing is silent. Babosa applies
        # transliterations in sequence and the first rule to define a character
        # consumes it, so caller rules come first and `:latin` comes last:
        # `:latin` knows "ö" and folds it to "o", which would swallow a request
        # for `:german` and quietly yield "malmo" rather than "malmoe". `:latin`
        # must still be present, because `to_ascii!` strips accents it has not
        # folded, turning "Café" into "caf".
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
