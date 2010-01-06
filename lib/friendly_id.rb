require "friendly_id/helpers"
require "friendly_id/slug"
require "friendly_id/slug_string"
require "friendly_id/sluggable_class_methods"
require "friendly_id/sluggable_instance_methods"
require "friendly_id/non_sluggable_class_methods"
require "friendly_id/non_sluggable_instance_methods"
require "friendly_id/config"

# FriendlyId is a comprehensive Ruby library for slugging and permalinks with
# ActiveRecord.
module FriendlyId


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
  def has_friendly_id(method, options = {}, &block)
    class_inheritable_accessor :friendly_id_config
    write_inheritable_attribute :friendly_id_config, Config.new(options.merge(
      :configured_class => self.class,
      :method => method,
      :normalizer => block
    ))
    class_inheritable_accessor :friendly_id_options
    write_inheritable_attribute :friendly_id_options, {}
    if friendly_id_config.use_slug?
      extend SluggableClassMethods
      include SluggableInstanceMethods
    else
      extend NonSluggableClassMethods
      include NonSluggableInstanceMethods
    end
  end

  # Parse the sequence and slug name from a friendly_id string.
  def self.parse(string)
    name, sequence = string.split('--')
    sequence ||= "1"
    return name, sequence
  end

end

class ActiveRecord::Base #:nodoc:#
  extend FriendlyId #:nodoc:#
end
