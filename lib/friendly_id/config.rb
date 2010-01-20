module FriendlyId

  class Config

    DEFAULT_OPTIONS = {
      :ascii_approximation_options => [],
      :max_length => 255,
      :reserved_words => ["index", "new"],
      :reserved_message => "can not be %s",
      :sequence_separator => "--"
    }

    # Strip diacritics from Western characters.
    attr_accessor :approximate_ascii

    # Locale-type options for ASCII approximations. These can be any of the
    # values supported by {SlugString#approximate_ascii!}.
    attr_accessor :ascii_approximation_options

    # The column used to cache the friendly_id string.
    attr_accessor :cache_column

    # An array of classes for which the configured class serves as a
    # FriendlyId scope.
    attr_reader :child_scopes

    # The class that's using the configuration.
    attr_reader :configured_class

    # The maximum allowed length for a friendly_id string. This is checked *after* a
    # string is processed by FriendlyId to remove spaces, special characters, etc.
    attr_accessor :max_length

    # The method or column that will be used as the basis of the friendly_id string.
    attr_reader :method

    # A block or proc through which to filter the friendly_id text.
    # This method will be removed from FriendlyId 3.0.
    # @deprecated Please override the +normalize_friendly_id+
    #   method in your model class rather than passing a block to {#has_friendly_id}.
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

    attr_reader :custom_cache_column

    def initialize(configured_class, method, options = nil, &block)
      @configured_class = configured_class
      @method = method.to_sym
      DEFAULT_OPTIONS.merge(options || {}).each do |key, value|
        self.send "#{key}=".to_sym, value
      end
      yield self if block_given?
    end

    def autodiscover_cache_column
      :cached_slug if configured_class.columns.any? { |column| column.name == 'cached_slug' }
    end

    def cache_column
      return @cache_column if defined?(@cache_column)
      @cache_column = autodiscover_cache_column
    end

    def cache_column=(cache_column)
      @cache_column = cache_column
      @custom_cache_column = cache_column
    end

    def child_scopes
      @child_scopes ||= associated_friendly_classes.select { |klass| klass.friendly_id_config.scopes_over?(configured_class) }
    end

    def normalizer=(arg)
      @normalizer = arg unless arg.nil?
    end

    def reserved_words=(*words)
      @reserved_words = words.flatten.uniq
    end

    def reserved?(word)
      reserved_words.include? word
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

    def scope_for(record)
      scope? ? record.send(scope).to_param : nil
    end

    def scopes_over?(klass)
      scope? && scope == klass.to_s.underscore.to_sym
    end

    # This method will be removed from FriendlyId 3.0.
    # @deprecated Please use {#approximate_ascii approximate_ascii}.
    def strip_diacritics=(*args)
      warn('The "strip_diacritics" option is deprecated and will be removed from FriendlyId 3.0. Please use "approximate_ascii".')
      self.strip_diacritics = *args
    end

    %w[approximate_ascii cache_column custom_cache_column normalizer scope
        strip_non_ascii use_slug].each do |method|
      class_eval(<<-EOM)
        def #{method}?
          !! #{method}
        end
      EOM
    end

    alias :use_slugs? :use_slug?

    private

    def associated_friendly_classes
      configured_class.reflect_on_all_associations.select { |assoc|
        assoc.klass.respond_to? :friendly_id_config
      }.map(&:klass)
    end

  end

end
