# encoding: utf-8

require 'friendly_id/helpers'
require 'friendly_id/slug'

# FriendlyId is a comprehensize Rails plugin/gem for slugging and permalinks.
module FriendlyId

  # Default options for has_friendly_id.
  DEFAULT_FRIENDLY_ID_OPTIONS = {
    :max_length => 255,
    :reserved => ["new", "index"],
    :reserved_message => 'can not be "%s"',
    :cache_column => nil,
    :scope => nil,
    :strip_diacritics => false,
    :strip_non_ascii => false,
    :use_slug => false
  }.freeze

  # This error is raised when it's not possible to generate a unique slug.
  class SlugGenerationError < StandardError ; end

  module ClassMethods

    # Set up an ActiveRecord model to use a friendly_id.
    #
    # The column argument can be one of your model's columns, or a method
    # you use to generate the slug.
    #
    # Options:
    # * <tt>:use_slug</tt> - Defaults to false. Use slugs when you want to use a non-unique text field for friendly ids.
    # * <tt>:max_length</tt> - Defaults to 255. The maximum allowed length for a slug.
    # * <tt>:cache_column</tt> - Defaults to nil. Use this column as a cache for generating to_param (experimental) Note that if you use this option, any calls to +attr_accessible+ must be made BEFORE any calls to has_friendly_id in your class.
    # * <tt>:strip_diacritics</tt> - Defaults to false. If true, it will remove accents, umlauts, etc. from western characters.
    # * <tt>:strip_non_ascii</tt> - Defaults to false. If true, it will all non-ascii ([^a-z0-9]) characters.
    # * <tt>:reserved</tt> - Array of words that are reserved and can't be used as friendly_id's. For sluggable models, if such a word is used, it will raise a FriendlyId::SlugGenerationError. Defaults to ["new", "index"].
    # * <tt>:reserved_message</tt> - The validation message that will be shown when a reserved word is used as a frindly_id. Defaults to '"%s" is reserved'.
    #
    # You can also optionally pass a block if you want to use your own custom
    # slugnormalization routines rather than the default ones that come with
    # friendly_id:
    #
    #   require 'stringex'
    #   class Post < ActiveRecord::Base
    #     has_friendly_id :title, :use_slug => true do |text|
    #       # Use stringex to generate the friendly_id rather than the baked-in methods
    #       text.to_url
    #     end
    #   end
    def has_friendly_id(method, options = {}, &block)
      options.assert_valid_keys DEFAULT_FRIENDLY_ID_OPTIONS.keys
      options = DEFAULT_FRIENDLY_ID_OPTIONS.merge(options).merge(:method => method)
      write_inheritable_attribute :friendly_id_options, options
      class_inheritable_accessor :friendly_id_options
      class_inheritable_reader :slug_normalizer_block
      friendly_id_options[:use_slug] ? set_up_with_slugs(&block) : set_up_without_slugs
    end

    private

    def set_up_with_slugs(&block)
      write_inheritable_attribute(:slug_normalizer_block, block) if block_given?
      configure_cached_slugs
      require 'friendly_id/sluggable_class_methods'
      require 'friendly_id/sluggable_instance_methods'
      extend SluggableClassMethods
      include SluggableInstanceMethods
      has_many :slugs, :order => 'id DESC', :as => :sluggable, :dependent => :destroy
      before_save :set_slug
      after_save :set_slug_cache
    end

    def set_up_without_slugs
      require 'friendly_id/non_sluggable_class_methods'
      require 'friendly_id/non_sluggable_instance_methods'
      extend NonSluggableClassMethods
      include NonSluggableInstanceMethods
      validate :validate_friendly_id
    end

    def configure_cached_slugs
      unless friendly_id_options[:cache_column]
        if columns.any? { |c| c.name == 'cached_slug' }
          friendly_id_options[:cache_column] = :cached_slug
        end
      end
      if friendly_id_options[:cache_column]
        # only protect the column if the class is not already using attributes_accessible
        attr_protected friendly_id_options[:cache_column].to_sym unless accessible_attributes
      end
    end
  end

  class << self

    # Load FriendlyId if the gem is included in a Rails app.
    def enable
      return if ActiveRecord::Base.methods.include? 'has_friendly_id'
      ActiveRecord::Base.class_eval { extend FriendlyId::ClassMethods }
    end

  end

end

if defined?(ActiveRecord)
  FriendlyId::enable
end
