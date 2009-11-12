require "friendly_id/helpers"
require "friendly_id/slug"
require "friendly_id/sluggable_class_methods"
require "friendly_id/sluggable_instance_methods"
require "friendly_id/non_sluggable_class_methods"
require "friendly_id/non_sluggable_instance_methods"

# FriendlyId is a comprehensive Ruby library for slugging and permalinks with
# ActiveRecord.
module FriendlyId

  # Default options for has_friendly_id.
  DEFAULT_OPTIONS = {
    :max_length       => 255,
    :reserved         => ["new", "index"],
    :reserved_message => 'can not be "%s"'
  }.freeze

  # The names of all valid configuration options.
  VALID_OPTIONS = (DEFAULT_OPTIONS.keys + [
    :cache_column,
    :scope,
    :strip_diacritics,
    :stip_non_ascii,
    :use_slug
  ]).freeze

  # This error is raised when it's not possible to generate a unique slug.
  class SlugGenerationError < StandardError ; end

  # Set up an ActiveRecord model to use a friendly_id.
  #
  # The column argument can be one of your model's columns, or a method
  # you use to generate the slug.
  #
  # Options:
  # * <tt>:use_slug</tt> - Defaults to nil. Use slugs when you want to use a non-unique text field for friendly ids.
  # * <tt>:max_length</tt> - Defaults to 255. The maximum allowed length for a slug.
  # * <tt>:cache_column</tt> - Defaults to nil. Use this column as a cache for generating to_param (experimental) Note that if you use this option, any calls to +attr_accessible+ must be made BEFORE any calls to has_friendly_id in your class.
  # * <tt>:strip_diacritics</tt> - Defaults to nil. If true, it will remove accents, umlauts, etc. from western characters.
  # * <tt>:strip_non_ascii</tt> - Defaults to nil. If true, it will remove all non-ASCII characters.
  # * <tt>:reserved</tt> - Array of words that are reserved and can't be used as friendly_id's. For sluggable models, if such a word is used, it will raise a FriendlyId::SlugGenerationError. Defaults to ["new", "index"].
  # * <tt>:reserved_message</tt> - The validation message that will be shown when a reserved word is used as a frindly_id. Defaults to '"%s" is reserved'.
  #
  # You can also optionally pass a block if you want to use your own custom
  # slug normalization routines rather than the default ones that come with
  # friendly_id:
  #
  #   require "stringex"
  #   class Post < ActiveRecord::Base
  #     has_friendly_id :title, :use_slug => true do |text|
  #       # Use stringex to generate the friendly_id rather than the baked-in methods
  #       text.to_url
  #     end
  #   end
  def has_friendly_id(method, options = {}, &block)
    options.assert_valid_keys VALID_OPTIONS
    options = DEFAULT_OPTIONS.merge(options).merge(:method => method)
    write_inheritable_attribute :friendly_id_options, options
    class_inheritable_accessor :friendly_id_options
    class_inheritable_reader :slug_normalizer_block
    write_inheritable_attribute(:slug_normalizer_block, block) if block_given?
    if friendly_id_options[:use_slug]
      extend SluggableClassMethods
      include SluggableInstanceMethods
    else
      extend NonSluggableClassMethods
      include NonSluggableInstanceMethods
    end
  end
end

class ActiveRecord::Base
  extend FriendlyId
end
