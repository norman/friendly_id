module FriendlyId

  # This class is not intended to be used on its own, it is used internally
  # by `has_friendly_id` to store a model's configuration and
  # configuration-related methods.
  #
  # The arguments accepted by +has_friendly_id+ correspond to the writeable
  # instance attributes of this class; please see the description of the
  # attributes below for information on the possible options.
  #
  # @example
  #   has_friendly_id :name,
  #    :use_slug => true,
  #    :max_length => 150,
  #    :approximate_ascii => true,
  #    :ascii_approximation_options => :german,
  #    :sequence_separator => ":",
  #    :reserved_words => ["reserved", "words"],
  #    :scope => :country,
  #    :cache_column => :my_cache_column_name
  #    # etc.
  class Configuration

    DEFAULTS = {
      :allow_nil                   => false,
      :ascii_approximation_options => [],
      :max_length                  => 255,
      :reserved_words              => ["index", "new"],
      :reserved_message            => 'can not be "%s"',
      :sequence_separator          => "--"
    }

    # Whether to allow friendly_id and/or slugs to be nil. This is not
    # generally useful on its own, but may allow you greater flexibility to
    # customize your application.
    attr_accessor :allow_nil
    alias :allow_nil? :allow_nil

    # Strip diacritics from Western characters.
    attr_accessor :approximate_ascii

    # Locale-type options for ASCII approximations.
    attr_accessor :ascii_approximation_options

    # The class that's using the configuration.
    attr_reader :configured_class

    # The maximum allowed byte length for a friendly_id string. This is checked *after* a
    # string is processed by FriendlyId to remove spaces, special characters, etc.
    attr_accessor :max_length

    # The method or column that will be used as the basis of the friendly_id string.
    attr_reader :method
    alias :column :method

    # The message shown when a reserved word is used.
    # @see #reserved_words
    attr_accessor :reserved_message

    # Array of words that are reserved and can't be used as friendly_id strings.
    # If a listed word is used in a sluggable model, it will raise a
    # FriendlyId::SlugGenerationError. For Rails applications, you are recommended
    # to include "index" and "new", which used as the defaults unless overridden.
    attr_accessor :reserved_words

    # The method or relation to use as the friendly_id's scope.
    attr_reader :scope

    # The string that separates slug names from slug sequences. Defaults to "--".
    attr_accessor :sequence_separator

    # Strip non-ASCII characters from the friendly_id string.
    attr_accessor :strip_non_ascii

    # Use slugs for storing the friendly_id string.
    attr_accessor :use_slug
    alias :use_slugs= :use_slug

    def initialize(configured_class, method, options = nil, &block)
      @configured_class = configured_class
      @method = method.to_sym
      DEFAULTS.merge(options || {}).each do |key, value|
        self.send "#{key}=".to_sym, value
      end
      yield self if block_given?
    end

    def cache_column=(value)
      @cache_column = value.to_s.strip.to_sym
      if value =~ /\s/ || [:slug, :slugs].include?(@cache_column)
        raise ArgumentError, "FriendlyId cache column can not be named '#{value}'"
      end
      @cache_column
    end

    # This should be overridden by adapters that implement caching.
    def cache_column?
      false
    end

    def reserved_words=(*words)
      @reserved_words = words.flatten.uniq
    end

    def reserved?(word)
      reserved_words.include? word.to_s
    end

    def reserved_error_message(word)
      [method, reserved_message % word] if reserved? word
    end

    def scope=(scope)
      self.class.scopes_used = true
      @scope = scope
    end

    def sequence_separator=(string)
      if string == "-" || string =~ /\s/
        raise ArgumentError, "FriendlyId sequence_separator can not be '#{string}'"
      end
      @sequence_separator = string
    end

    # This will be set if FriendlyId's scope feature is used in any model. It is here
    # to provide a way to avoid invoking costly scope lookup methods when the scoped
    # slug feature is not being used by any models.
    def self.scopes_used=(val)
      @scopes_used = !!val
    end

    # Are scoped slugs being used by any model?
    # @see Configuration.scoped_used=
    def self.scopes_used?
      @scopes_used
    end

    %w[approximate_ascii scope strip_non_ascii use_slug].each do |method|
      class_eval(<<-EOM, __FILE__, __LINE__ +1)
        def #{method}?
          !! #{method}
        end
      EOM
    end

    alias :use_slugs? :use_slug?

    def babosa_options
      {
        :to_ascii         => strip_non_ascii?,
        :transliterate    => approximate_ascii?,
        :transliterations => ascii_approximation_options,
        :max_length       => max_length
      }
    end
  end
end
