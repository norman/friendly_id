# FriendlyId is a Rails plugin which lets you use text-based ids in addition
# to numeric ones.
module Randomba
  module FriendlyId

    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
    end

    module ClassMethods

      # Set up an ActiveRecord model to use a friendly_id.
      # 
      # The method argument can be one of your model's columns, or a method you
      # use to generate the slug.
      #
      # Options:
      # * <tt>:use_slug</tt> - Defaults to false. Use slugs when you want to use a non-unique text field for friendly ids.
      # * <tt>:max_length</tt> - Defaults to 255. The maximum allowed length for a slug.
      # * <tt>:strip_diacritics</tt> - Defaults to false. If true, it will remove accents, umlauts, etc. from western characters. You must have the unicode gem installed for this to work.
      def has_friendly_id(method, options = {})

        options = default_friendly_id_options.merge(options).merge(:method => method)
        write_inheritable_attribute(:friendly_id_options, options)
        class_inheritable_reader :friendly_id_options

        if options[:use_slug]
          has_many :slugs, :order => "id DESC", :as => :sluggable
          before_save :set_slug
          include SluggableInstanceMethods
          extend SluggableClassMethods  
        else
          include NonSluggableInstanceMethods
          extend NonSluggableClassMethods  
        end
      end

      # Gets the default options for friendly_id.
      def default_friendly_id_options
        {
          :method => nil,
          :use_slug => false,
          :max_length => 255,
          :strip_diacritics => false
        }
      end

    end

    module SingletonMethods
      # Extends ActiveRecord::Base::find to allow simple finds by the
      # friendly id:
      #   @record = Record.find("record name")
      def find(*args)
        find_using_friendly_id(args.first) or super(*args)
      end
    end

    module NonSluggableClassMethods
      # Finds the record using only the friendly id. If it can't be found using
      # the friendly id, then it returns false. If you pass in any argument other
      # than an instance of String, then it also returns false.    
      def find_using_friendly_id(slug_text)
        return false unless slug_text.kind_of?(String)
        finder = "find_by_#{self.friendly_id_options[:method].to_s}".to_sym
        record = send(finder, slug_text)
        record.send(:found_using_friendly_id=, true) if record
        return record
      end    
    end

    module NonSluggableInstanceMethods

      def self.included(base)
        base.extend SingletonMethods
      end

      attr :found_using_friendly_id

      # Was the record found using one of its friendly ids?
      def found_using_friendly_id?
        @found_using_friendly_id
      end

      # Was the record found using its numeric id?
      def found_using_numeric_id?
        ! @found_using_friendly_id
      end

      alias has_better_id? found_using_numeric_id?

      # Returns the friendly_id.
      def friendly_id
        send(friendly_id_options[:method].to_sym)
      end

      alias best_id friendly_id

      # Returns the friendly id, or if none is available, the numeric id.
      def to_param
        friendly_id ? friendly_id : id
      end 

      private

      def found_using_friendly_id=(value)
        @found_using_friendly_id = value
      end

    end

    module SluggableClassMethods

      # Finds the record using only the friendly id. If it can't be found using
      # the friendly id, then it returns false. If you pass in any argument other
      # than an instance of String, then it also returns false.
      def find_using_friendly_id(slug_text)
        return false unless slug_text.kind_of?(String)
        slug = Slug.find_by_name_and_sluggable_type(slug_text, self.to_s)      
        return false if !slug
        return false if !slug.sluggable      
        slug.sluggable.send(:finder_slug=, slug)
        slug.sluggable
      end
    end  

    module SluggableInstanceMethods

      def self.included(base)
        base.extend SingletonMethods
      end

      attr :finder_slug

      # Was the record found using one of its friendly ids?
      def found_using_friendly_id?
        !!@finder_slug
      end

      # Was the record found using its numeric id?
      def found_using_numeric_id?
        !found_using_friendly_id?
      end

      # Was the record found using an old friendly id?
      def found_using_outdated_friendly_id?
        @finder_slug.id != slug.id
      end

      # Was the record found using an old friendly id, or its numeric id?
      def has_better_id?
        found_using_numeric_id? || found_using_outdated_friendly_id?
      end

      # Returns the friendly id.
      def friendly_id
        slug.name
      end

      alias best_id friendly_id

      # Returns the most recent slug, which is used to determine the friendly id.
      def slug
        slugs.first
      end

      # Returns the friendly id, or if none is available, the numeric id.
      def to_param
        slug ? slug.name : id
      end

      # Generate the text for the friendly id, ensuring no duplication.
      def generate_friendly_id
        max_length = friendly_id_options[:max_length]
        slug_text = friendly_id_base[0, max_length - NUM_CHARS_RESERVED_FOR_EXTENSION]
        count = Slug.count_matches(slug_text, self.class.to_s, :all,
        :conditions => "sluggable_id <> #{self.id or 0}")
        if count == 0
          return slug_text
        else
          generate_friendly_id_with_extension(slug_text, count)
        end
      end

      # Set the slug using the generated friendly id.
      def set_slug
        return unless self.class.friendly_id_options[:use_slug]
        slug_text = generate_friendly_id
        if slugs.empty? || slugs.first.name != slug_text 
          slugs.build(:name => slug_text)
        end
      end

      # Remove diacritis from the string.
      def strip_diacritics(string)
        require 'iconv'
        require 'unicode'
        Iconv.new("ascii//translit//ignore", "utf-8").iconv(Unicode.normalize_KD(string))
      end

      # Get the string used as the basis of the friendly id. If you set the option
      # to remove diacritics from the friendly id's then they will be removed.
      def friendly_id_base
        if self.friendly_id_options[:strip_diacritics]
          Slug::normalize(strip_diacritics(send(self.friendly_id_options[:method].to_sym)))
        else
          Slug::normalize(send(self.friendly_id_options[:method].to_sym))
        end
      end


      protected

      # Sets the slug that was used to find the record. This can be used to
      # determine whether the record was found using the most recent friendly id.    
      def finder_slug=(val)
        @finder_slug = val
      end

      private

      # Reserve a few spaces at the end of the slug for the counter extension.
      # This is to avoid generating slugs longer than the maxlength when an
      # extension is added.
      NUM_CHARS_RESERVED_FOR_EXTENSION = 2

      def generate_friendly_id_with_extension(slug_text, count)
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
    end

    # This error is raised when it's not possible to generate a unique slug.
    class SlugGenerationError < StandardError ; end

  end
end