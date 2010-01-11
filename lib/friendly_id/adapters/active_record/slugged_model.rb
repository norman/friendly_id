module FriendlyId
  module Adapters
    module ActiveRecord
      module SluggedModel

        class Status < ::FriendlyId::Status

          attr_accessor :slug

          # The slug that was used to find the model.
          def slug
            @slug ||= model.slugs.find_by_name_and_sequence(*name.to_s.parse_friendly_id(
              model.friendly_id_config.sequence_separator))
          end

          # Did the find operation use a friendly id?
          def friendly?
            !! (name or slug)
          end

          # Did the find operation use the current slug?
          def current?
            !! slug && slug.is_most_recent?
          end

          # Did the find operation use an outdated slug?
          def outdated?
            !current?
          end

          # Did the find operation use the best possible id? True if +id+ is 
          # numeric, but the model has no slug, or +id+ is friendly and current
          def best?
            current? || (numeric? && !model.slug)
          end

        end

        class MultipleFinder < FriendlyId::Finder
          def all_friendly?
            [friendly?].flatten.compact.uniq == [true]
          end

          def all_unfriendly?
            [unfriendly?].flatten.compact.uniq == [true]
          end

          def friendly?
            ids.map {|id| self.class.friendly? id}
          end

          def unfriendly?
            ids.map {|id| self.class.unfriendly? id}
          end
        end

        class SingleFinder < FriendlyId::Finder

          def find
            result = model.send(:with_scope, {:find => find_options}) { model.send(:find_initial, options) }
            raise ::ActiveRecord::RecordNotFound.new if friendly? and !result
            result.friendly_id_status.name = name if result
            result
          rescue ::ActiveRecord::RecordNotFound => @error
            friendly_id_config.scope? ? raise_scoped_error : (raise @error)
          end

          def find_options
            slug_table = Slug.table_name
            {
              :select => "#{model.table_name}.*",
              :joins => slugs_included? ? options[:joins] : :slugs,
              :conditions => {
                "#{slug_table}.name"     => name,
                "#{slug_table}.scope"    => scope,
                "#{slug_table}.sequence" => sequence
              }
            }
          end
          
          def raise_scoped_error
            scope_message = options[:scope] || "expected, but none given"
            message = "%s, scope: %s" % [@error.message, scope_message]
            raise ::ActiveRecord::RecordNotFound, message
          end

        end
        
        module Finders
          
          # Finds a single record using the friendly id, or the record's id.
          def find_one(id_or_name, options) #:nodoc:#
            finder = SingleFinder.new(id_or_name, self, options)
            finder.unfriendly? ? super : finder.find or super
          end

          # Finds multiple records using the friendly ids, or the records' ids.
          def find_some(ids_and_names, options) #:nodoc:#

            finder = MultipleFinder.new(ids_and_names, options)
            slugs, ids = get_slugs_and_ids(ids_and_names, options)
            results = []

            find_options = {:select => "#{self.table_name}.*"}
            find_options[:joins] = :slugs unless options[:include] && [*options[:include]].flatten.include?(:slugs)
            find_options[:conditions] = "#{quoted_table_name}.#{primary_key} IN (#{ids.empty? ? 'NULL' : ids.join(',')}) "
            find_options[:conditions] << "OR slugs.id IN (#{slugs.to_s(:db)})"

            results = with_scope(:find => find_options) { find_every(options) }.uniq

            if results.size != expected = finder.expected_size
              raise ::ActiveRecord::RecordNotFound, "Couldn't find all #{ name.pluralize } with IDs (#{ ids_and_names * ', ' }) AND #{ sanitize_sql options[:conditions] } (found #{ results.size } results, but was looking for #{ expected })"
            end

            assign_finders(slugs, results)

            results
          end

          def validate_find_options(options) #:nodoc:#
            options.assert_valid_keys([:conditions, :include, :joins, :limit, :offset,
              :order, :select, :readonly, :group, :from, :lock, :having, :scope])
          end

          def cache_column
            if defined?(@cache_column)
              return @cache_column
            elsif friendly_id_config.cache_column
              @cache_column = friendly_id_config.cache_column
            elsif columns.any? { |c| c.name == 'cached_slug' }
              @cache_column = :cached_slug
            else
              @cache_column = nil
            end
          end

          private

          # Assign finder slugs for the results found in find_some_with_friendly
          def assign_finders(slugs, results) #:nodoc:#
            slugs.each do |slug|
              results.select { |r| r.id == slug.sluggable_id }.each do |result|
                result.friendly_id_status.slug = slug
              end
            end
          end

          # Build arrays of slugs and ids, for the find_some_with_friendly method.
          def get_slugs_and_ids(ids_and_names, options) #:nodoc:#
            scope = options.delete(:scope)
            slugs = []
            ids = []
            ids_and_names.each do |id_or_name|
              name, sequence = id_or_name.to_s.parse_friendly_id(friendly_id_config.sequence_separator)
              slug = Slug.find(:first, :conditions => {
                :name           => name,
                :scope          => scope,
                :sequence       => sequence,
                :sluggable_type => base_class.name
              })
              # If the slug was found, add it to the array for later use. If not, and
              # the id_or_name is a number, assume that it is a regular record id.
              slug ? slugs << slug : (ids << id_or_name if id_or_name.to_s =~ /\A\d*\z/)
            end
            return slugs, ids
          end

        end

        module DeprecatedMethods
          # @deprecated Please use #friendly_id_status.slug.
          def finder_slug
            friendly_id_status.slug
          end

          # Was the record found using one of its friendly ids?
          # @deprecated Please use #friendly_id_status.friendly?
          def found_using_friendly_id?
            friendly_id_status.friendly?
          end

          # Was the record found using its numeric id?
          # @deprecated Please use #friendly_id_status.numeric?
          def found_using_numeric_id?
            friendly_id_status.numeric?
          end

          # Was the record found using an old friendly id?
          # @deprecated Please use #friendly_id_status.outdated?
          def found_using_outdated_friendly_id?
            friendly_id_status.outdated?
          end

          # Was the record found using an old friendly id, or its numeric id?
          # @deprecated Please use !#friendly_id_status.best?
          def has_better_id?
            ! friendly_id_status.best?
          end
        end

        def self.included(base)
          base.class_eval do
            has_many :slugs, :class_name => "FriendlyId::Adapters::ActiveRecord::Slug", :order => 'id DESC', :as => :sluggable, :dependent => :destroy
            before_save :set_slug
            after_save :set_slug_cache
            # only protect the column if the class is not already using attributes_accessible
            if !accessible_attributes
              if friendly_id_config.cache_column
                attr_protected friendly_id_config.cache_column
              end
              attr_protected :cached_slug
            end
            extend(Finders)
          end
        end
        
        include DeprecatedMethods

        def friendly_id_status
          @friendly_id_status ||= Status.new(:model => self)
        end

        # Does the record have (at least) one slug?
        def slug?
          !! slug
        end
        alias :has_a_slug? :slug?

        # Returns the friendly id.
        # @FIXME
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
          @slug = nil if reload
          @slug ||= slugs.first(:order => "id DESC")
        end

        # Returns the friendly id, or if none is available, the numeric id.
        def to_param
          if cache_column
            read_attribute(cache_column) || id.to_s
          else
            slug ? slug.to_friendly_id : id.to_s
          end
        end

        def normalize_friendly_id(string)
          if friendly_id_config.normalizer?
            SlugString.new friendly_id_config.normalizer.call(string)
          else
            string = SlugString.new string
            string.approximate_ascii! if friendly_id_config.approximate_ascii?
            string.to_ascii! if friendly_id_config.strip_non_ascii?
            string.normalize!
            string
          end
        end

        private

        # Get the processed string used as the basis of the friendly id.
        def slug_text
          base = normalize_friendly_id(send(friendly_id_config.method))
          if base.length > friendly_id_config.max_length
            base = base[0...friendly_id_config.max_length]
          end
          if friendly_id_config.reserved_words.include?(base.to_s)
            raise SlugGenerationError.new("The slug text is a reserved value")
          elsif base.blank?
            raise SlugGenerationError.new("The slug text is blank")
          end
          return base.to_s
        end


        def cache_column
          self.class.cache_column
        end

        # Set the slug using the generated friendly id.
        def set_slug
          if friendly_id_config.use_slug? && new_slug_needed?
            @slug = nil
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
    end
  end
end