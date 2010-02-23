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
  # has_friendly_id :name,
  #  :use_slug => true,
  #  :max_length => 150,
  #  :approximate_ascii => true,
  #  :ascii_approximation_options => :german,
  #  :sequence_separator => ":",
  #  :reserved_words => ["reserved", "words"],
  #  :scope => :country,
  #  :cache_column => :my_cache_column_name
  #  # etc.
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

    # Locale-type options for ASCII approximations. These can be any of the
    # values supported by {SlugString#approximate_ascii!}.
    attr_accessor :ascii_approximation_options

    # The class that's using the configuration.
    attr_reader :configured_class

    # The maximum allowed length for a friendly_id string. This is checked *after* a
    # string is processed by FriendlyId to remove spaces, special characters, etc.
    attr_accessor :max_length

    # The method or column that will be used as the basis of the friendly_id string.
    attr_reader :method
    alias :column :method

    # A block or proc through which to filter the friendly_id text.
    # This method will be removed from FriendlyId 3.0.
    # @deprecated Please override the +normalize_friendly_id+
    #   method in your model class rather than passing a block to `has_friendly_id`.
    attr_accessor :normalizer

    # The message shown when a reserved word is used.
    # @see #reserved_words
    attr_accessor :reserved_message

    # Array of words that are reserved and can't be used as friendly_id strings.
    # If a listed word is used in a sluggable model, it will raise a
    # FriendlyId::SlugGenerationError. For Rails applications, you are recommended
    # to include "index" and "new", which used as the defaults unless overridden.
    attr_accessor :reserved_words

    # The method or relation to use as the friendly_id's scope.
    attr_accessor :scope

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

    def normalizer=(arg)
      return if arg.nil?
      raise("passing a block to has_friendly_id is deprecated and will be removed from 3.0. Please override #friendly_id_normalizer.")
      @normalizer = arg
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

    # This method will be removed from FriendlyId 3.0.
    # @deprecated Please use {#reserved_words reserved_words}.
    def reserved=(*args)
      warn('The "reserved" option is deprecated and will be removed from FriendlyId 3.0. Please use "reserved_words".')
      self.reserved_words = *args
    end

    # This method will be removed from FriendlyId 3.0.
    # @deprecated Please use {#approximate_ascii approximate_ascii}.
    def strip_diacritics=(*args)
      warn('strip_diacritics is deprecated and will be removed from 3.0. Please use #approximate_ascii')
      self.approximate_ascii = *args
    end

    %w[approximate_ascii normalizer scope strip_non_ascii use_slug].each do |method|
      class_eval(<<-EOM)
        def #{method}?
          !! #{method}
        end
      EOM
    end

    alias :use_slugs? :use_slug?

  end

end
