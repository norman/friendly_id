module SluggableInstanceMethods

  NUM_CHARS_RESERVED_FOR_FRIENDLY_ID_EXTENSION = 2

  attr :finder_slug
  attr_accessor :finder_slug_name

  def finder_slug
    @finder_slug ||= init_finder_slug
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
    slug(true).name
  end
  alias best_id friendly_id

  # Returns the most recent slug, which is used to determine the friendly
  # id.
  def slug(reload = false)
    @most_recent_slug = nil if reload
    @most_recent_slug ||= slugs.first
  end

  # Returns the friendly id, or if none is available, the numeric id.
  def to_param
    (slug && !slug.name.blank?) ? slug.name : id.to_s
  end

  # Generate the text for the friendly id, ensuring no duplication.
  def generate_friendly_id
    base = friendly_id_base
    opts = self.class.friendly_id_options
    if base.length > opts[:max_length]
      base = base[0...opts[:max_length] - NUM_CHARS_RESERVED_FOR_FRIENDLY_ID_EXTENSION]
    end
    if opts[:reserved].include?(base)
      base = "#{base}-2"
    end
    Slug.get_best_name(base, self.class)
  end

  # Set the slug using the generated friendly id.
  def set_slug
    if self.class.friendly_id_options[:use_slug]
      @most_recent_slug = nil
      slug_text = generate_friendly_id
      # Avoids regenerating slug over and over again.
      # FIXME This could perform pretty badly if a model has tons of similarly-named slugs
      return if slug && slug.succ == slug_text
      if slugs.empty? || slugs.first.name != slug_text
        previous_slug = slugs.find_by_name friendly_id_base
        previous_slug.destroy if previous_slug
        name = generate_friendly_id

        slug_attributes = {:name => name}
        if friendly_id_options[:scope]
          scope = send(friendly_id_options[:scope])
          slug_attributes[:scope] = scope.respond_to?(:to_param) ? scope.to_param : scope.to_s
        end

        # If all name characters are removed, don't create a useless slug
        slugs.build slug_attributes unless slug_attributes[:name].blank?

      end
    end
  end

  # Get the string used as the basis of the friendly id. If you set the
  # option to remove diacritics from the friendly id's then they will be
  # removed.
  def friendly_id_base
    base = send friendly_id_options[:column]
    if base.blank?
      raise FriendlyId::SlugGenerationError.new('The method or column used as the base of friendly_id\'s slug text returned a blank value')
    elsif self.friendly_id_options[:strip_diacritics]
      Slug::normalize(Slug::strip_diacritics(base))
    else
      Slug::normalize(base)
    end
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
    slug = Slug.find(:first, :conditions => {:sluggable_id => id, :name => @finder_slug_name})
    finder_slug = slug
  end

end
