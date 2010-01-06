module FriendlyId::SluggableInstanceMethods

  def self.included(base)
    base.class_eval do
      has_many :slugs, :order => 'id DESC', :as => :sluggable, :dependent => :destroy
      before_save :set_slug
      after_save :set_slug_cache
      # only protect the column if the class is not already using attributes_accessible
      if !accessible_attributes
        if friendly_id_config.cache_column
          attr_protected friendly_id_config.cache_column
        end
        attr_protected :cached_slug
      end
    end
  end

  NUM_CHARS_RESERVED_FOR_FRIENDLY_ID_EXTENSION = 2

  attr :finder_slug
  attr_accessor :finder_slug_name

  def finder_slug
    @finder_slug ||= init_finder_slug or nil
  end

  # Was the record found using one of its friendly ids?
  def found_using_friendly_id?
    !!@finder_slug_name
  end

  # Was the record found using its numeric id?
  def found_using_numeric_id?
    !found_using_friendly_id?
  end

  # Was the record found using an old friendly id?
  def found_using_outdated_friendly_id?
    return false if cache_column && send(cache_column) == @finder_slug_name
    finder_slug.id != slug.id
  end

  # Was the record found using an old friendly id, or its numeric id?
  def has_better_id?
    has_a_slug? and found_using_numeric_id? || found_using_outdated_friendly_id?
  end

  # Does the record have (at least) one slug?
  def has_a_slug?
    @finder_slug_name || slug
  end

  # Returns the friendly id.
  def friendly_id
    slug(true).to_friendly_id
  end
  alias best_id friendly_id

  # Has the basis of our friendly id changed, requiring the generation of a
  # new slug?
  def new_slug_needed?
    !slug || slug_text != slug.name
  end

  # Returns the most recent slug, which is used to determine the friendly
  # id.
  def slug(reload = false)
    @most_recent_slug = nil if reload
    @most_recent_slug ||= slugs.first(:order => "id DESC")
  end

  # Returns the friendly id, or if none is available, the numeric id.
  def to_param
    if cache_column
      read_attribute(cache_column) || id.to_s
    else
      slug ? slug.to_friendly_id : id.to_s
    end
  end

  # Get the processed string used as the basis of the friendly id.
  def slug_text

    base = send friendly_id_config.method

    if self.friendly_id_config.normalizer
      base = SlugString.new(self.friendly_id_config.normalizer.call(base))
    else
      base = SlugString.new base
      if self.friendly_id_config.approximate_ascii?
        base.approximate_ascii!
      end
      if self.friendly_id_config.strip_non_ascii?
        base.to_ascii!
      end
      base.normalize!
    end

    if base.length > friendly_id_config.max_length
      base = base[0...friendly_id_config.max_length]
    end

    if friendly_id_config.reserved_words.include?(base.to_s)
      raise FriendlyId::SlugGenerationError.new("The slug text is a reserved value")
    elsif base.blank?
      raise FriendlyId::SlugGenerationError.new("The slug text is blank")
    end

    return base.to_s

  end

private

  def cache_column
    self.class.cache_column
  end

  def finder_slug=(finder_slug)
    @finder_slug_name = finder_slug.name
    slug = finder_slug
    slug.sluggable = self
    slug
  end

  def init_finder_slug
    return false if !@finder_slug_name
    name, sequence = FriendlyId.parse(@finder_slug_name)
    slug = Slug.find(:first, :conditions => {:sluggable_id => id, :name => name, :sequence => sequence, :sluggable_type => self.class.base_class.name })
    finder_slug = slug
  end

  # Set the slug using the generated friendly id.
  def set_slug
    if self.class.friendly_id_config.use_slug? && new_slug_needed?
      @most_recent_slug = nil
      slug_attributes = {:name => slug_text}
      if friendly_id_config.scope?
        scope = send(friendly_id_config.scope)
        slug_attributes[:scope] = scope.respond_to?(:to_param) ? scope.to_param : scope.to_s
      end
      # If we're renaming back to a previously used friendly_id, delete the
      # slug so that we can recycle the name without having to use a sequence.
      slugs.find(:all, :conditions => {:name => slug_text, :scope => slug_attributes[:scope]}).each { |s| s.destroy }
      slugs.build slug_attributes
    end
  end

  def set_slug_cache
    if cache_column && send(cache_column) != slug.to_friendly_id
      send "#{cache_column}=", slug.to_friendly_id
      send :update_without_callbacks
    end
  end

end
