module FriendlyId

  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    
    def has_friendly_id(options = {})
      
      options = default_friendly_id_options.merge(options)
      write_inheritable_attribute(:friendly_id_options, options)
      class_inheritable_reader :friendly_id_options
      
      if options[:use_slug]
        has_many :slugs, :order => "slugs.id DESC", :as => :sluggable
        before_save :set_slug
        include SluggableInstanceMethods
        extend SluggableClassMethods  
      end

      class << self
        alias old_find find
        
        def find(*args)
          if friendly_id_options[:use_slug]
            find_using_slug(args.first) or old_find(*args)
          else
            old_find(*args)
          end
        end      
        
      end
      
    end
    
    def default_friendly_id_options
      {
        :column => "name",
        :use_slug => false,
        :max_length => 255,
        :strip_diacritics => false
      }
    end
  
  end
  
  module SluggableClassMethods
    def find_using_slug(slug_text)
      return false unless slug_text.kind_of?(String)
      slug = Slug.find_by_name_and_sluggable_type(slug_text, self.to_s)      
      return false if !slug
      return false if !slug.sluggable      
      slug.sluggable.send(:finder_slug=, slug)
      slug.sluggable
    end
  end  
  
  module SluggableInstanceMethods
    
    attr :finder_slug
    
    def found_using_friendly_id?
      !!@finder_slug
    end

    def found_using_numeric_id?
      !found_using_friendly_id?
    end
    
    def found_using_outdated_friendly_id?
      @finder_slug.id != slug.id
    end
    
    def has_better_id?
      found_using_numeric_id? || found_using_outdated_friendly_id?
    end
    
    def best_id
      slug.name
    end
    
    alias friendly_id best_id

    def finder_slug=(val)
      @finder_slug = val
    end
    protected :finder_slug=
    
    def slug
      slugs.first
    end
    
    def to_param
      slug ? slug.name : id
    end
    
    def generate_slug
      max_length = friendly_id_options[:max_length]
      slug_text = slug_base[0, max_length - NUM_CHARS_RESERVED_FOR_EXTENSION]
      count = Slug.count_matches(slug_text, self.class.to_s, :all,
        :conditions => "sluggable_id <> #{self.id or 0}")
      if count == 0
        return slug_text
      else
        generate_slug_with_extension(slug_text, count)
      end
    end
    
    def set_slug
      slug_text = generate_slug
      if slugs.empty? || slugs.first.name != slug_text 
        slugs.build(:name => slug_text)
      end
    end
  
  private
  
    NUM_CHARS_RESERVED_FOR_EXTENSION = 2
    
    def generate_slug_with_extension(slug_text, count)
      extension = "-" + (count + 1).to_s
      if extension.length > NUM_CHARS_RESERVED_FOR_EXTENSION
        raise FriendlyId::SlugGenerationError.new("slug text #{slug_text} " +
          "goes over limit for similarly named slugs")
      end
      slug_text = slug_text + extension
      count = Slug.count_matches(slug_text, self.class.to_s, :all,
        :conditions => "id <> #{self.id or 0}")
      if count != 0
        raise FriendlyId::SlugGenerationError.new("I give up, damnit!")
      else
        return slug_text
      end
    
    end
  
    def strip_diacritics(string)
      require 'iconv'
      require 'unicode'
      Iconv.new("ascii//translit//ignore", "utf-8").iconv(Unicode.normalize_KD(string))
    end
    
    def slug_base
      if self.friendly_id_options[:strip_diacritics]
        Slug::normalize(strip_diacritics(send(self.friendly_id_options[:column].to_sym)))
      else
        Slug::normalize(send(self.friendly_id_options[:column].to_sym))
      end
    end
  
  end
  
  class SlugGenerationError < StandardError ; end
  
end