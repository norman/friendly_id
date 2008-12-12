# FriendlyId is a comprehensize Rails plugin/gem for slugging and permalinks.
module FriendlyId

  # Load FriendlyId if the gem is included in a Rails app.
  def self.enable
    return if ActiveRecord::Base.methods.include? 'has_friendly_id'
    ActiveRecord::Base.class_eval { extend FriendlyId::ClassMethods }
  end


  # This error is raised when it's not possible to generate a unique slug.
  class SlugGenerationError < StandardError ; end

  module ClassMethods

    # Default options for friendly_id.
    DEFAULT_FRIENDLY_ID_OPTIONS = {:method => nil, :use_slug => false, :max_length => 255, :reserved => [], :strip_diacritics => false, :scope => nil}.freeze
    VALID_FRIENDLY_ID_KEYS = [:use_slug, :max_length, :reserved, :strip_diacritics, :scope].freeze

    # Set up an ActiveRecord model to use a friendly_id.
    #
    # The column argument can be one of your model's columns, or a method
    # you use to generate the slug.
    #
    # Options:
    # * <tt>:use_slug</tt> - Defaults to false. Use slugs when you want to use a non-unique text field for friendly ids.
    # * <tt>:max_length</tt> - Defaults to 255. The maximum allowed length for a slug.
    # * <tt>:strip_diacritics</tt> - Defaults to false. If true, it will remove accents, umlauts, etc. from western characters.
    # * <tt>:reseved</tt> - Array of words that are reserved and can't be used as slugs. If such a word is used, it will be treated the same as if that slug was already taken (numeric extension will be appended). Defaults to [].
    def has_friendly_id(column, options = {})
      options.assert_valid_keys VALID_FRIENDLY_ID_KEYS
      options = DEFAULT_FRIENDLY_ID_OPTIONS.merge(options).merge(:column => column)
      write_inheritable_attribute :friendly_id_options, options
      class_inheritable_reader :friendly_id_options

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
      end
    end

  end

end

if defined?(ActiveRecord)
  FriendlyId::enable
end