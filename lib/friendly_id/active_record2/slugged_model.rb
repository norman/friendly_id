module FriendlyId
  module ActiveRecord2
    module SluggedModel

      module SluggedFinder
        # Whether :include => :slugs has been passed as an option.
        def slugs_included?
          [*(options[:include] or [])].flatten.include?(:slugs)
        end
      end

      class MultipleFinder

        include FriendlyId::Finders::Base
        include FriendlyId::ActiveRecord2::Finders::Multiple
        include SluggedFinder

        attr_reader :slugs

        def find
          @results = with_scope(:find => find_options) { all options }.uniq
          raise ::ActiveRecord::RecordNotFound, error_message if @results.size != expected_size
          @results.each {|result| result.friendly_id_status.name = slug_for(result)}
        end

        private

        def find_conditions
          slugs
          # [unfriendly_find_conditions, friendly_find_conditions].compact.join(" OR ")
          ids = (unfriendly_ids + sluggable_ids).join(",")
          "%s IN (%s)" % ["#{quoted_table_name}.#{primary_key}", ids]
        end

        def friendly_find_conditions
          "slugs.id IN (%s)" % slugs.compact.to_s(:db) if slugs?
        end

        def find_options
          {:select => "#{table_name}.*", :conditions => find_conditions,
            :joins => slugs_included? ? options[:joins] : :slugs}
        end

        def sluggable_ids
          if !@sluggable_ids
            @sluggable_ids ||= []
            slugs
          end
          @sluggable_ids
        end

        def slugs
          @sluggable_ids ||= []
          @slugs ||= friendly_ids.map do |friendly_id|
            name, sequence = friendly_id.parse_friendly_id(friendly_id_config.sequence_separator)
            slug = Slug.first :conditions => {
              :name           => name,
              :scope          => scope,
              :sequence       => sequence,
              :sluggable_type => base_class.name
            }
            sluggable_ids << slug.sluggable_id if slug
            slug
          end
        end

        def slugs?
          !slugs.empty?
        end

        def slug_for(result)
          slugs.select {|slug| result.id == slug.sluggable_id}.first
        end

        def unfriendly_find_conditions
          "%s IN (%s)" % ["#{quoted_table_name}.#{primary_key}", unfriendly_ids.join(",")] if unfriendly_ids?
        end

        def unfriendly_ids?
          ! unfriendly_ids.empty?
        end

      end

      # Performs a find a single friendly_id using the cached_slug column,
      # if available. This is significantly faster, and can be used in all
      # circumstances unless the +:scope+ argument is present.
      class CachedMultipleFinder < SimpleModel::MultipleFinder
        # The column used to store the cached slug.
        def column
          "#{table_name}.#{friendly_id_config.cache_column}"
        end
      end

      class SingleFinder

        include FriendlyId::Finders::Base
        include FriendlyId::Finders::Single
        include SluggedFinder

        def find
          result = with_scope({:find => find_options}) { find_initial options }
          raise ::ActiveRecord::RecordNotFound.new if friendly? and !result
          result.friendly_id_status.name = name if result
          result
        rescue ::ActiveRecord::RecordNotFound => @error
          friendly_id_config.scope? ? raise_scoped_error : (raise @error)
        end

        private

        def find_options
          slug_table = Slug.table_name
          {
            :select => "#{model_class.table_name}.*",
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

      # Performs a find for multiple friendly_ids using the cached_slug column,
      # if available. This is significantly faster, and can be used in all
      # circumstances unless the +:scope+ argument is present.
      class CachedSingleFinder < SimpleModel::SingleFinder

        # The column used to store the cached slug.
        def column
          "#{table_name}.#{friendly_id_config.cache_column}"
        end

      end

      # The methods in this module override ActiveRecord's +find_one+ and
      # +find_some+ to add FriendlyId's features.
      module FinderMethods

        protected

        def find_one(id_or_name, options)
          finder = Finders::FinderProxy.new(id_or_name, self, options)
          finder.unfriendly? ? super : finder.find or super
        end

        def find_some(ids_and_names, options)
          Finders::FinderProxy.new(ids_and_names, self, options).find
        end

        # Since Rails goes out of its way to make these options completely
        # inaccessible, we have to copy them here.
        def validate_find_options(options)
          options.assert_valid_keys([:conditions, :include, :joins, :limit, :offset,
            :order, :select, :readonly, :group, :from, :lock, :having, :scope])
        end

      end

      # These methods will be removed in FriendlyId 3.0.
      module DeprecatedMethods

        # @deprecated Please use #to_param
        def best_id
          warn("best_id is deprecated and will be removed in 3.0. Please use #to_param.")
          to_param
        end

        # @deprecated Please use #friendly_id_status.slug.
        def finder_slug
          warn("finder_slug is deprecated and will be removed in 3.0. Please use #friendly_id_status.slug.")
          friendly_id_status.slug
        end

        # Was the record found using one of its friendly ids?
        # @deprecated Please use #friendly_id_status.friendly?
        def found_using_friendly_id?
          warn("found_using_friendly_id? is deprecated and will be removed in 3.0. Please use #friendly_id_status.friendly?")
          friendly_id_status.friendly?
        end

        # Was the record found using its numeric id?
        # @deprecated Please use #friendly_id_status.numeric?
        def found_using_numeric_id?
          warn("found_using_numeric_id is deprecated and will be removed in 3.0. Please use #friendly_id_status.numeric?")
          friendly_id_status.numeric?
        end

        # Was the record found using an old friendly id?
        # @deprecated Please use #friendly_id_status.outdated?
        def found_using_outdated_friendly_id?
          warn("found_using_outdated_friendly_id is deprecated and will be removed in 3.0. Please use #friendly_id_status.outdated?")
          friendly_id_status.outdated?
        end

        # Was the record found using an old friendly id, or its numeric id?
        # @deprecated Please use !#friendly_id_status.best?
        def has_better_id?
          warn("has_better_id? is deprecated and will be removed in 3.0. Please use !#friendly_id_status.best?")
          ! friendly_id_status.best?
        end

        # @deprecated Please use #slug?
        def has_a_slug?
          warn("has_a_slug? is deprecated and will be removed in 3.0. Please use #slug?")
          slug?
        end

      end

      def self.included(base)
        base.class_eval do
          has_many :slugs, :order => 'id DESC', :as => :sluggable, :dependent => :destroy
          before_save :build_slug
          after_save :set_slug_cache
          after_update :update_scope
          after_update :update_dependent_scopes
          protect_friendly_id_attributes
          extend FinderMethods
        end
      end

      include Slugged
      include DeprecatedMethods

      def find_slug(name)
        separator = friendly_id_config.sequence_separator
        slugs.find_by_name_and_sequence(*name.to_s.parse_friendly_id(separator))
      end

      # The model instance's current {FriendlyId::ActiveRecord2::Slug slug}.
      def slug
        return @slug if new_record?
        @slug ||= slugs.first(:order => "id DESC")
      end

      # Set the slug.
      def slug=(slug)
        @new_friendly_id = slug.to_friendly_id unless slug.nil?
        super
      end

      # Returns the friendly id, or if none is available, the numeric id.
      def to_param
        friendly_id_config.cache_column ? to_param_from_cache : to_param_from_slug
      end

      private

      def scope_changed?
        friendly_id_config.scope? && send(friendly_id_config.scope).to_param != slug.scope
      end

      # Respond with the cached value if available.
      def to_param_from_cache
        read_attribute(friendly_id_config.cache_column) || id.to_s
      end

      # Respond with the slugged value if available.
      def to_param_from_slug
        slug? ? slug.to_friendly_id : id.to_s
      end

      # Build the new slug using the generated friendly id.
      def build_slug
        return unless new_slug_needed?
        self.slug = slugs.build :name => slug_text.to_s, :scope => friendly_id_config.scope_for(self)
      end

      # Reset the cached friendly_id?
      def new_cache_needed?
        uses_slug_cache? && send(friendly_id_config.cache_column) != slug.to_friendly_id
      end

      # Reset the cached friendly_id.
      def set_slug_cache
        if new_cache_needed?
          send "#{friendly_id_config.cache_column}=", slug.to_friendly_id
          send :update_without_callbacks
        end
      end

      def update_scope
        return unless scope_changed?
        slug.update_attributes :scope => send(friendly_id_config.scope).to_param
      rescue ActiveRecord::StatementInvalid
        slug.update_attributes :sequence => Slug.similar_to(slug).first.sequence.succ
      end

      # Update the slugs for any model that is using this model as its
      # FriendlyId scope.
      def update_dependent_scopes
        if slugs(true).size > 1 && @new_friendly_id
          friendly_id_config.child_scopes.each do |klass|
            Slug.update_all "scope = '#{@new_friendly_id}'", ["sluggable_type = ? AND scope = ?",
              klass.to_s, slugs.second.to_friendly_id]
          end
        end
      end

      # Does the model use slug caching?
      def uses_slug_cache?
        friendly_id_config.cache_column?
      end

    end
  end
end
