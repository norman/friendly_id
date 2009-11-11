# encoding: utf-8

module FriendlyId::SluggableInstanceMethods

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
    if cache = friendly_id_options[:cache_column]
      return false if send(cache) == @finder_slug_name
    end
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
    if cache = friendly_id_options[:cache_column]
      return read_attribute(cache) || id.to_s
    end
    slug ? slug.to_friendly_id : id.to_s
  end

  # Get the processed string used as the basis of the friendly id.
  def slug_text
    base = send friendly_id_options[:method]
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

    if base.mb_chars.length > friendly_id_options[:max_length]
      base = base.mb_chars[0...friendly_id_options[:max_length]]
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
      slugs.build slug_attributes
    end
  end

  def set_slug_cache
    if friendly_id_options[:cache_column] && send(friendly_id_options[:cache_column]) != slug.to_friendly_id
      send "#{friendly_id_options[:cache_column]}=", slug.to_friendly_id
      send :update_without_callbacks
    end
  end

end
