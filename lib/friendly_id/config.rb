module FriendlyId

  class Config

    DEFAULT_OPTIONS = {
      :ascii_approximation_options => [],
      :max_length => 255,
      :reserved_words => ["index", "new"],
      :reserved_message => "can not be %s"
    }

    # Strip diacritics from Western characters.
    attr_accessor :approximate_ascii
    alias :strip_diacritics= :approximate_ascii=

    # Locale-type options for ASCII approximations. These can be any of the
    # values supported by {SlugString#approximate_ascii!}.
    attr_accessor :ascii_approximation_options

    # The column used to cache the friendly_id string.
    attr_accessor :cache_column

    # The class that's using the configuration.
    attr_accessor :configured_class

    # The maximum allowed length for a slug.
    # @see DEFAULT_MAX_LENGTH
    attr_accessor :max_length

    # The method or column that will be used as the basis of the friendly_id string.
    attr_accessor :method

    # A block or proc through which to filter the friendly_id text.
    attr_accessor :normalizer

    # The message shown when a reserved word is used.
    # @see #reserved_words
    attr_accessor :reserved_message

    # Array of words that are reserved and can't be used as friendly_id strings.
    # If a listed word is used in a sluggable model, it will raise a
    # FriendlyId::SlugGenerationError. For Rails applications, you are recommended
    # to include "index" and "new", which used as the defaults unless overridden.
    # @see DEFAULT_RESERVED_WORDS
    attr_accessor :reserved_words

    # The method or relation to use as the friendly_id's scope.
    attr_accessor :scope

    # Strip non-ASCII characters from the friendly_id string.
    attr_accessor :strip_non_ascii

    # Use slugs for storing the friendly_id string.
    attr_accessor :use_slug
    alias :use_slugs= :use_slug

    def initialize(options = nil, &block)
      DEFAULT_OPTIONS.merge(options || {}).each do |key, value|
        self.send "#{key}=".to_sym, value
      end
      yield self if block_given?
    end

    def cache_column=(*args)
      @cache_column = args[0].to_sym unless args.empty?
    end

    def max_length=(*args)
      @max_length = args[0].to_i unless args.empty?
    end

    def method=(*args)
      @method = args[0].to_sym unless args.empty?
    end

    def reserved_words=(*words)
      @reserved_words = words.flatten.uniq
    end

    %w[approximate_ascii scope strip_non_ascii use_slug].each do |method|
      class_eval(<<-EOM)
        def #{method}?
          !! @#{method}
        end
      EOM
    end

    alias :use_slugs? :use_slug?

  end

end
