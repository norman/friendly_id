require 'friendly_id/helpers'
require 'friendly_id/slug'

# FriendlyId is a comprehensize Rails plugin/gem for slugging and permalinks.
module FriendlyId

  # Default options for has_friendly_id.
  DEFAULT_FRIENDLY_ID_OPTIONS = {
    :max_length => 255,
    :method => nil,
    :reserved => ["new", "index"],
    :reserved_message => 'can not be "%s"',
    :scope => nil,
    :strip_diacritics => false,
    :strip_non_ascii => false,
    :use_slug => false }.freeze
  
  # Valid keys for has_friendly_id options.
  VALID_FRIENDLY_ID_KEYS = [
    :max_length,
    :reserved,
    :reserved_message,
    :scope,
    :strip_diacritics,
    :strip_non_ascii,
    :use_slug ].freeze
    
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
    # * <tt>:strip_diacritics</tt> - Defaults to false. If true, it will remove accents, umlauts, etc. from western characters.
    # * <tt>:strip_non_ascii</tt> - Defaults to false. If true, it will all non-ascii ([^a-z0-9]) characters.
    # * <tt>:reseved</tt> - Array of words that are reserved and can't be used as friendly_id's. For sluggable models, if such a word is used, it will be treated the same as if that slug was already taken (numeric extension will be appended). Defaults to ["new", "index"].
    # * <tt>:reseved_message</tt> - The validation message that will be shown when a reserved word is used as a frindly_id. Defaults to '"%s" is reserved'.
    def has_friendly_id(column, options = {})
      options.assert_valid_keys VALID_FRIENDLY_ID_KEYS
      options = DEFAULT_FRIENDLY_ID_OPTIONS.merge(options).merge(:column => column)
      write_inheritable_attribute :friendly_id_options, options
      class_inheritable_accessor :friendly_id_options

      if options[:use_slug]
        has_many :slugs, :order => 'id DESC', :as => :sluggable, :dependent => :destroy
        require 'friendly_id/sluggable_class_methods'
        require 'friendly_id/sluggable_instance_methods'
        extend SluggableClassMethods
        include SluggableInstanceMethods
        before_save :set_slug
      else
        require 'friendly_id/non_sluggable_class_methods'
        require 'friendly_id/non_sluggable_instance_methods'
        extend NonSluggableClassMethods
        include NonSluggableInstanceMethods
        validate_on_create :validate_friendly_id
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
