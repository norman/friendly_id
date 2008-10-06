# FriendlyId is a Rails plugin which lets you use text-based ids in addition
# to numeric ones.
module Randomba
  module FriendlyId

    # This error is raised when it's not possible to generate a unique slug.
    SlugGenerationError = Class.new StandardError

    module ClassMethods

      # Default options for friendly_id.
      DEFAULT_FRIENDLY_ID_OPTIONS = {:method => nil, :use_slug => false, :max_length => 255, :strip_diacritics => false}.freeze
      VALID_FRIENDLY_ID_KEYS = [:use_slug, :max_length, :strip_diacritics].freeze

      # Set up an ActiveRecord model to use a friendly_id.
      #
      # The method argument can be one of your model's columns, or a method
      # you use to generate the slug.
      #
      # Options:
      # * <tt>:use_slug</tt> - Defaults to false. Use slugs when you want to use a non-unique text field for friendly ids.
      # * <tt>:max_length</tt> - Defaults to 255. The maximum allowed length for a slug.
      # * <tt>:strip_diacritics</tt> - Defaults to false. If true, it will remove accents, umlauts, etc. from western characters. You must have the unicode gem installed for this to work.
      def has_friendly_id(column, options = {})
        options.assert_valid_keys VALID_FRIENDLY_ID_KEYS
        options = DEFAULT_FRIENDLY_ID_OPTIONS.merge(options).merge(:column => column)
        write_inheritable_attribute :friendly_id_options, options
        class_inheritable_reader :friendly_id_options

        if options[:use_slug]
          extend SluggableClassMethods
          include SluggableInstanceMethods
          has_many :slugs, :order => 'id DESC', :as => :sluggable, :dependent => :destroy
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
        if "#{ id }" =~ /^\d+$/
          find_one_without_friendly id, options
        else
          if r = send("find_by_#{ friendly_id_options[:column] }", id, options)
            r.found_using_friendly_id = true and r
          else
            raise ActiveRecord::RecordNotFound, "Couldn't find #{ name } with SLUG=#{ id }#{ options[:conditions] }"
          end
        end
      end
      def find_some_with_friendly(ids_and_slugs, options)
        conditions  = " AND (#{ sanitize_sql options[:conditions] })" if options[:conditions]

        ids, slugs  = [], []
        ids_and_slugs.each { |x| ("#{ x }" =~ /^\d+$/ ? ids : slugs) << x }
        column      = columns_hash[primary_key]
        ids         = ids.map { |id| quote_value id, column }.join ','
        column      = columns_hash[friendly_id_options[:column]]
        slugs       = slugs.map { |slug| quote_value slug, column }.join ','

        options[:conditions] = "(#{ quoted_table_name }.#{ connection.quote_column_name primary_key } IN (#{ ids }) OR #{ quoted_table_name }.#{ connection.quote_column_name friendly_id_options[:column] } IN (#{ slugs }))#{ conditions }"

        result = find_every(options).each { |s| s.found_using_friendly_id = true }

        expected_size = options[:offset] ? ids_and_slugs.size - options[:offset] : ids_and_slugs.size
        expected_size = options[:limit] if options[:limit] && expected_size > options[:limit]

        result.size == expected_size or
        raise ActiveRecord::RecordNotFound, "Couldn't find all #{name.pluralize} with SLUG/IDs (#{ids_and_slugs * ', '})#{conditions} (found #{result.size} results, but was looking for #{expected_size})"

        result
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
        friendly_id || id
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
        end
      end

      # Finds the record using only the friendly id. If it can't be found
      # using the friendly id, then it returns false. If you pass in any
      # argument other than an instance of String or Array, then it also
      # returns false. When given as an array will try to find any of the
      # records and return those that can be found.
      def find_one_with_friendly(id, options)
        if "#{ id }" =~ /^\d+$/
          find_one_without_friendly id, options
        else
          sluggable_type = name
          Slug.instance_eval do
            conditions = " AND (#{ sanitize_sql options[:conditions] })" if options[:conditions]
            options.update :conditions => "#{ quoted_table_name }.#{ connection.quote_column_name 'name' } = #{ quote_value id, columns_hash['name'] } AND #{ quoted_table_name }.#{ connection.quote_column_name 'sluggable_type' } = #{ quote_value sluggable_type, columns_hash['type'] }#{ conditions }"

            options[:include] = include_sluggable options[:include]

            slug = find_every(options).first and result = slug.sluggable or
            raise ActiveRecord::RecordNotFound, "Couldn't find #{ name } with SLUG=#{ id }#{ conditions }"

            result.finder_slug = slug
            result
          end
        end
      end
      def find_some_with_friendly(ids_and_slugs, options)
        conditions  = " AND (#{ sanitize_sql options[:conditions] })" if options[:conditions]

        ids, slugs  = [], []
        ids_and_slugs.each { |x| ("#{ x }" =~ /^\d+$/ ? ids : slugs) << x }
        column      = columns_hash[:sluggable_id]
        ids         = ids.map { |id| quote_value id, column }.join ','
        column      = columns_hash[:name]
        slugs       = slugs.map { |slug| quote_value slug, column }.join ','

        sluggable_type = name
        Slug.instance_eval do
          options[:conditions] = "(#{ quoted_table_name }.#{ connection.quote_column_name 'sluggable_id' } IN (#{ ids }) OR #{ quoted_table_name }.#{ connection.quote_column_name 'name' } IN (#{ slugs })) AND #{ quoted_table_name }.#{ connection.quote_column_name 'sluggable_type' } = #{ quote_value sluggable_type, columns_hash['type'] }#{ conditions }"
          options[:include] = include_sluggable options[:include]

          result = find_every(options).inject([]) do |m, s|
            unless s.sluggable then m
            else
              s.sluggable.finder_slug = s
              m << s.sluggable
            end
          end

          expected_size = options[:offset] ? ids_and_slugs.size - options[:offset] : ids_and_slugs.size
          expected_size = options[:limit] if options[:limit] && expected_size > options[:limit]

          result.size == expected_size or
          raise ActiveRecord::RecordNotFound, "Couldn't find all #{name.pluralize} with SLUG/IDs (#{ids_and_slugs * ', '})#{conditions} (found #{result.size} results, but was looking for #{expected_size})"

          result
        end
      end
    end

    module SluggableInstanceMethods

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
        slug and found_using_numeric_id? || found_using_outdated_friendly_id?
      end

      # Returns the friendly id.
      def friendly_id
        slug.name
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
        slug ? slug.name : id
      end

      # Generate the text for the friendly id, ensuring no duplication.
      def generate_friendly_id
        slug_text = truncated_friendly_id_base

        count = Slug.count_matches slug_text, self.class.name, :all, :conditions => "sluggable_id <> #{ id.to_i }"
        count == 0 ? slug_text : generate_friendly_id_with_extension(slug_text, count)
      end

      # Set the slug using the generated friendly id.
      def set_slug
        if self.class.friendly_id_options[:use_slug]
          @most_recent_slug = nil
          slug_text = generate_friendly_id

          if slugs.empty? || slugs.first.name != slug_text
            previous_slug = slugs.find_by_name slug_text
            previous_slug.destroy if previous_slug

            slugs.build :name => slug_text
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
          Slug::normalize Slug::strip_diacritics(base)
        else
          Slug::normalize base
        end
      end

      protected
      # Sets the slug that was used to find the record. This can be used to
      # determine whether the record was found using the most recent friendly
      # id.
      def finder_slug=(val)
        @finder_slug = val
      end

      private
      NUM_CHARS_RESERVED_FOR_FRIENDLY_ID_EXTENSION = 2
      def truncated_friendly_id_base
        max_length = friendly_id_options[:max_length]
        slug_text = friendly_id_base[0, max_length - NUM_CHARS_RESERVED_FOR_FRIENDLY_ID_EXTENSION]
      end

      # Reserve a few spaces at the end of the slug for the counter extension.
      # This is to avoid generating slugs longer than the maxlength when an
      # extension is added.
      POSSIBILITIES = 10 ** NUM_CHARS_RESERVED_FOR_FRIENDLY_ID_EXTENSION - 1
      def generate_friendly_id_with_extension(slug_text, count)
        count <= POSSIBILITIES or
        raise FriendlyId::SlugGenerationError.new("slug text #{slug_text} goes over limit for similarly named slugs")

        slug_text = "#{ truncated_friendly_id_base }-#{ count + 1 }"

        count = Slug.count_matches slug_text, self.class.name, :all, :conditions => "sluggable_id <> #{ id.to_i }"
        count > 0 ? "#{ truncated_friendly_id_base }-#{ count + 1 }" : slug_text
      end
    end

  end
end
