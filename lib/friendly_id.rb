# FriendlyId is a Rails plugin which lets you use text-based ids in addition
# to numeric ones.
module FriendlyId
  
  # Load the view helpers if the gem is included in a Rails app.
  def self.enable
    return if ActiveRecord::Base.methods.include? 'has_friendly_id'
    ActiveRecord::Base.class_eval { extend FriendlyId::ClassMethods }
  end


  # This error is raised when it's not possible to generate a unique slug.
  SlugGenerationError = Class.new StandardError

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
        extend SluggableClassMethods
        include SluggableInstanceMethods
        before_save :set_slug
      else
        extend NonSluggableClassMethods
        include NonSluggableInstanceMethods
      end
    end

  end

  module NonSluggableClassMethods

    def self.extended(base)
      class << base
        alias_method_chain :find_one, :friendly
        alias_method_chain :find_some, :friendly
      end
    end

    # Finds the record using only the friendly id. If it can't be found
    # using the friendly id, then it returns false. If you pass in any
    # argument other than an instance of String or Array, then it also
    # returns false.
    # def find_using_friendly_id()
    #   return false unless slug_text.kind_of?(String)
    #   finder = "find_by_#{self.friendly_id_options[:column].to_s}".to_sym
    #   record = send(finder, slug_text)
    #   record.send(:found_using_friendly_id=, true) if record
    #   return record
    # end
    def find_one_with_friendly(id, options)
      if id.is_a?(String) && result = send("find_by_#{ friendly_id_options[:column] }", id, options)
        result.found_using_friendly_id = true
      else
        result = find_one_without_friendly id, options
      end
      result
    end

    def find_some_with_friendly(ids_and_names, options)
      results_by_name = with_scope :find => options do
        find :all, :conditions => ["#{ quoted_table_name }.#{ friendly_id_options[:column] } IN (?)", ids_and_names]
      end

      ids     = ids_and_names - results_by_name.map { |r| r[ friendly_id_options[:column] ] }
      results = results_by_name

      results += with_scope :find => options do
        find :all, :conditions => ["#{ quoted_table_name }.#{ primary_key } IN (?)", ids]
      end unless ids.empty?

      expected_size = options[:offset] ? ids_and_names.size - options[:offset] : ids_and_names.size
      expected_size = options[:limit] if options[:limit] && expected_size > options[:limit]

      raise ActiveRecord::RecordNotFound, "Couldn't find all #{ name.pluralize } with IDs (#{ ids_and_names * ', ' }) AND #{ sanitize_sql options[:conditions] } (found #{ results.size } results, but was looking for #{ expected_size })" if results.size != expected_size

      results_by_name.each { |r| r.found_using_friendly_id = true }
      results
    end
  end

  module NonSluggableInstanceMethods

    attr :found_using_friendly_id

    # Was the record found using one of its friendly ids?
    def found_using_friendly_id?
      @found_using_friendly_id
    end

    # Was the record found using its numeric id?
    def found_using_numeric_id?
      !@found_using_friendly_id
    end
    alias has_better_id? found_using_numeric_id?

    # Returns the friendly_id.
    def friendly_id
      send friendly_id_options[:column]
    end

    alias best_id friendly_id

    # Returns the friendly id, or if none is available, the numeric id.
    def to_param
      friendly_id.to_s || id.to_s
    end

    def found_using_friendly_id=(value)
      @found_using_friendly_id = value
    end

  end

  module SluggableClassMethods

    def self.extended(base)

      class << base
        alias_method_chain :find_one, :friendly
        alias_method_chain :find_some, :friendly
        alias_method_chain :validate_find_options, :friendly
      end

      base.named_scope :with_slug_name, lambda {|slug_names| {
        :conditions => {"#{Slug.table_name}.name" => slug_names.to_a}
      }}
      base.named_scope :with_slug_scope, lambda {|slug_scope| {
        :conditions => {"#{Slug.table_name}.scope" => slug_scope}
      }}
      
    end
    
    # Finds a single record using the friendly_id, or the record's id.
    def find_one_with_friendly(id_or_name, options)

      scope = options.delete(:scope)

      return find_one_without_friendly(id_or_name, options) if id_or_name.is_a?(Fixnum)
      find_options = {:select => "#{self.table_name}.*"}
      find_options[:joins] = :slugs unless options[:include] && [*options[:include]].flatten.include?(:slugs)

      result = with_scope :find => find_options do
        with_slug_name(id_or_name).with_slug_scope(scope).find_initial(options)
      end

      if result
        result.finder_slug_name = id_or_name
      else
        result = find_one_without_friendly id_or_name, options
      end

      result

    end

    # Finds multiple records using the friendly_ids, or the records' ids.
    def find_some_with_friendly(ids_and_names, options)
      slugs = Slug.find_all_by_names_and_sluggable_type ids_and_names, base_class.name

      # separate ids and slug names
      names = slugs.map { |s| s[:name] }
      ids   = ids_and_names - names

      # search in slugs and own table
      results = []

      scope = options.delete(:scope)

      find_options = {:select => "#{self.table_name}.*"}
      find_options[:joins] = :slugs unless options[:include] && [*options[:include]].flatten.include?(:slugs)

      unless names.empty?
        results += with_scope(:find => find_options) do
          with_slug_name(ids_and_names).with_slug_scope(scope).find_every options
        end
      end

      unless ids.empty?
        find_options[:conditions] = {"#{table_name}.#{primary_key}" => ids}
        results += with_scope(:find => find_options) do
           find_every options
        end
      end

      # calculate expected size, taken from active_record/base.rb
      expected_size = options[:offset] ? ids_and_names.size - options[:offset] : ids_and_names.size
      expected_size = options[:limit] if options[:limit] && expected_size > options[:limit]

      if results.size != expected_size
        raise ActiveRecord::RecordNotFound, "Couldn't find all #{ name.pluralize } with IDs (#{ ids_and_names * ', ' }) AND #{ sanitize_sql options[:conditions] } (found #{ results.size } results, but was looking for #{ expected_size })"
      end

      # assign finder slugs
      slugs.each do |slug|
        results.select { |r| r.id == slug.sluggable_id }.each do |result|
          result.send(:finder_slug=, slug)
        end
      end
      results
    end

    def validate_find_options_with_friendly(options) #:nodoc:
      options.assert_valid_keys([:conditions, :include, :joins, :limit, :offset,
        :order, :select, :readonly, :group, :from, :lock, :having, :scope])
    end

  end

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
        raise SlugGenerationError.new('The method or column used as the base of friendly_id\'s slug text returned a blank value')
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

end

if defined?(ActiveRecord)
  FriendlyId::enable
end