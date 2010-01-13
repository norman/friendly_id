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

        class MultipleFinder < Finders::MultipleFinder

          attr_reader :slugs

          def find
            @results = with_scope(:find => find_options) { find_every options }.uniq
            raise(::ActiveRecord::RecordNotFound, error_message) if @results.size != expected_size
            @results.each {|result| result.friendly_id_status.slug = slug_for(result)}
          end

          private

          def find_conditions
            [unfriendly_find_conditions, friendly_find_conditions].compact.join(" OR ")
          end

          def friendly_find_conditions
            return if slugs.empty?
            "slugs.id IN (%s)" % slugs.compact.to_s(:db)
          end

          def find_options
            {:select => "#{table_name}.*", :conditions => find_conditions,
              :joins => slugs_included? ? options[:joins] : :slugs}
          end

          def slugs
            @slugs ||= friendly_ids.map do |friendly_id|
              name, sequence = friendly_id.parse_friendly_id(friendly_id_config.sequence_separator)
              Slug.first(:conditions => {
                :name           => name,
                :scope          => scope,
                :sequence       => sequence,
                :sluggable_type => base_class.name
              })
            end
          end

          def slug_for(result)
            slugs.select {|slug| result.id == slug.sluggable_id}.first
          end

          def unfriendly_find_conditions
            return if unfriendly_ids.empty?
            "%s IN (%s)" % ["#{quoted_table_name}.#{primary_key}", unfriendly_ids.join(",")]
          end

        end

        class SingleFinder < Finders::SingleFinder

          def find
            result = with_scope({:find => find_options}) { find_initial options }
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

        module ClassMethods

          def cache_column
            if defined?(@cache_column)
              return @cache_column
            elsif friendly_id_config.cache_column
              @cache_column = friendly_id_config.cache_column
            elsif columns.any? { |column| column.name == 'cached_slug' }
              @cache_column = :cached_slug
            else
              @cache_column = nil
            end
          end

          protected

          # Finds a single record using the friendly id, or the record's id.
          def find_one(id_or_name, options) #:nodoc:#
            finder = SingleFinder.new(id_or_name, self, options)
            finder.unfriendly? ? super : finder.find or super
          end

          # Finds multiple records using the friendly ids, or the records' ids.
          def find_some(ids_and_names, options) #:nodoc:#
            finder = MultipleFinder.new(ids_and_names, self, options).find
          end

          # Since Rails goes out of its way to make these options completely
          # inaccessible, we have to copy them here.
          def validate_find_options(options)
            options.assert_valid_keys([:conditions, :include, :joins, :limit, :offset,
              :order, :select, :readonly, :group, :from, :lock, :having, :scope])
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

          # @deprecated Please use #slug?
          def has_a_slug?
            slug?
          end

        end

        def self.included(base)
          base.class_eval do
            has_many :slugs, :class_name => "FriendlyId::Adapters::ActiveRecord::Slug",
              :order => 'id DESC', :as => :sluggable, :dependent => :destroy
            before_save :set_slug
            after_save :set_slug_cache
            protect_friendly_id_attributes
            extend ClassMethods
          end
        end

        include DeprecatedMethods

        def friendly_id_status
          @friendly_id_status ||= Status.new(:model => self)
        end

        # Returns the friendly id.
        # @FIXME
        def friendly_id
          slug.to_friendly_id
        end
        alias best_id friendly_id

        # Has the basis of our friendly id changed, requiring the generation of a
        # new slug?
        def new_slug_needed?
          !slug || slug_text != slug.name
        end

        # Returns the friendly id, or if none is available, the numeric id.
        def to_param
          cache_column ? to_param_from_cache : to_param_from_slug
        end

        def normalize_friendly_id(string)
          SlugString.new(string).normalize_for!(friendly_id_config).to_s
        end

        def slug
          @slug ||= slugs.first(:order => "id DESC")
        end

        def slug=(slug)
          @slug = slug
        end

        private

        # Get the processed string used as the basis of the friendly id.
        def slug_text
          normalize_friendly_id(send(friendly_id_config.method))
        end

        def to_param_from_cache
          read_attribute(cache_column) || id.to_s
        end

        def to_param_from_slug
          slug ? slug.to_friendly_id : id.to_s
        end

        def cache_column
          self.class.cache_column
        end

        # Set the slug using the generated friendly id.
        def set_slug
          return unless new_slug_needed?
          self.slug = slugs.build :name => slug_text, :scope => friendly_id_config.scope_for(self)
        end

        def set_slug_cache
          cache = cache_column
          if cache && send(cache) != slug.to_friendly_id
            send "#{cache}=", slug.to_friendly_id
            send :update_without_callbacks
          end
        end

      end
    end
  end
end