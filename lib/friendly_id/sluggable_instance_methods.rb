module FriendlyId::SluggableInstanceMethods

  NUM_CHARS_RESERVED_FOR_FRIENDLY_ID_EXTENSION = 2

  attr :finder_slug
  attr_accessor :finder_slug_name

  def finder_slug
    @finder_slug ||= init_finder_slug or nil
  end

  # Was the record found using one of its friendly ids?
  def found_using_friendly_id?
    finder_slug
  end

  # Was the record found using its numeric id?
  def found_using_numeric_id?
    !found_using_friendly_id?
  end

  # Was the record found using an old friendly id?
  def found_using_outdated_friendly_id?
    finder_slug.id != slug.id
  end

  # Was the record found using an old friendly id, or its numeric id?
  def has_better_id?
    slug and found_using_numeric_id? || found_using_outdated_friendly_id?
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
    @most_recent_slug ||= slugs.first
  end

  # Returns the friendly id, or if none is available, the numeric id.
  def to_param
    slug ? slug.to_friendly_id : id.to_s
  end

  # Get the processed string used as the basis of the friendly id.
  def slug_text
    base = send friendly_id_options[:column]
    if self.slug_normalizer_block
      base = self.slug_normalizer_block.call(base)
    else
      if self.friendly_id_options[:strip_diacritics]
        base = Slug::strip_diacritics(base)
      end
      if self.friendly_id_options[:strip_non_ascii]
        base = Slug::strip_non_ascii(base)
      end
      base = Slug::normalize(base)
    end
    
    if base.length > friendly_id_options[:max_length]
      base = base[0...friendly_id_options[:max_length]]
    end
    if friendly_id_options[:reserved].include?(base)
      raise FriendlyId::SlugGenerationError.new("The slug text is a reserved value")
    end
    return base
  end

  private

  def finder_slug=(finder_slug)
    @finder_slug_name = finder_slug.name
    slug = finder_slug
    slug.sluggable = self
    slug
  end

  def init_finder_slug
    return false if !@finder_slug_name
    name, sequence = Slug.parse(@finder_slug_name)
    slug = Slug.find(:first, :conditions => {:sluggable_id => id, :name => name, :sequence => sequence, :sluggable_type => self.class.base_class.name })
    finder_slug = slug
  end

  # Set the slug using the generated friendly id.
  def set_slug
    if self.class.friendly_id_options[:use_slug] && new_slug_needed?
      @most_recent_slug = nil
      slug_attributes = {:name => slug_text}
      if friendly_id_options[:scope]
        scope = send(friendly_id_options[:scope])
        slug_attributes[:scope] = scope.respond_to?(:to_param) ? scope.to_param : scope.to_s
      end
      # If we're renaming back to a previously used friendly_id, delete the
      # slug so that we can recycle the name without having to use a sequence.
      slugs.find(:all, :conditions => {:name => slug_text, :scope => scope}).each { |s| s.destroy }
      slug = slugs.build slug_attributes
      slug
    end
  end

end
