module FriendlyId
  module ActiveRecord2
    module SluggedModel

      class Status < FriendlyId::Status
        attr_accessor :slug

        # The slug that was used to find the model.
        def slug
          @slug ||= record.slugs.find_by_name_and_sequence(*name.to_s.parse_friendly_id(separator))
        end

        # Did the find operation use a friendly id?
        def friendly?
          !! (name or slug)
        end

        # Did the find operation use the current slug?
        def current?
          !! slug && slug.current?
        end

        # Did the find operation use an outdated slug?
        def outdated?
          !current?
        end

        def separator
          record.friendly_id_config.sequence_separator
        end

        # Did the find operation use the best possible id? True if +id+ is
        # numeric, but the model has no slug, or +id+ is friendly and current
        def best?
          current? || (numeric? && !record.slug)
        end

      end

      class MultipleFinder < Finders::MultipleFinder

        attr_reader :slugs

        def find
          @results = with_scope(:find => find_options) { all options }.uniq
          raise ::ActiveRecord::RecordNotFound, error_message if @results.size != expected_size
          @results.each {|result| result.friendly_id_status.slug = slug_for(result)}
        end

        private

        def find_conditions
          [unfriendly_find_conditions, friendly_find_conditions].compact.join(" OR ")
        end

        def friendly_find_conditions
          "slugs.id IN (%s)" % slugs.compact.to_s(:db) if slugs?
        end

        def find_options
          {:select => "#{table_name}.*", :conditions => find_conditions,
            :joins => slugs_included? ? options[:joins] : :slugs}
        end

        def slugs
          @slugs ||= friendly_ids.map do |friendly_id|
            name, sequence = friendly_id.parse_friendly_id(friendly_id_config.sequence_separator)
            Slug.first :conditions => {
              :name           => name,
              :scope          => scope,
              :sequence       => sequence,
              :sluggable_type => base_class.name
            }
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

      class SingleFinder < Finders::SingleFinder

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

      # The methods in this module override ActiveRecord's +find_one+ and
      # +find_some+ to add FriendlyId's features.
      module FinderMethods

        protected

        def find_one(id_or_name, options)
          finder = SingleFinder.new(id_or_name, self, options)
          finder.unfriendly? ? super : finder.find or super
        end

        def find_some(ids_and_names, options)
          finder = MultipleFinder.new(ids_and_names, self, options).find
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
          has_many :slugs, :class_name => "FriendlyId::ActiveRecord2::Slug",
            :order => 'id DESC', :as => :sluggable, :dependent => :destroy
          before_save :build_slug
          after_save :set_slug_cache
          after_update :update_scopes
          protect_friendly_id_attributes
          extend FinderMethods
        end
      end

      include DeprecatedMethods

      # Get the {FriendlyId::Status} after the find has been performed.
      def friendly_id_status
        @friendly_id_status ||= Status.new(:record => self)
      end

      # The friendly id.
      def friendly_id
        slug.to_friendly_id
      end

      # Clean up the string before setting it as the friendly_id. You can override
      # this method to add your own custom normalization routines.
      # @param string An instance of {FriendlyId::SlugString}.
      # @return [String]
      def normalize_friendly_id(string)
        string.normalize_for!(friendly_id_config).to_s
      end

      # The model instance's current {FriendlyId::ActiveRecord2::Slug slug}.
      def slug
        @slug ||= slugs.first(:order => "id DESC")
      end

      # Set the slug.
      def slug=(slug)
        @slug = slug
        @new_friendly_id = @slug.to_friendly_id
      end

      # Does the instance have a slug?
      def slug?
        !! slug
      end

      # Returns the friendly id, or if none is available, the numeric id.
      def to_param
        friendly_id_config.cache_column ? to_param_from_cache : to_param_from_slug
      end

      private

      # Has the basis of our friendly id changed, requiring the generation of a
      # new slug?
      def new_slug_needed?
        !slug || slug_text_changed?
      end

      # Get the processed string used as the basis of the friendly id.
      def slug_text
        normalize_friendly_id(SlugString.new(send(friendly_id_config.method)))
      end

      # Has the slug text changed?
      def slug_text_changed?
        slug_text != slug.name
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

      # Update the slugs for any model that is using this model as its
      # FriendlyId scope.
      def update_scopes
        if slugs(true).size > 1 && @new_friendly_id
          friendly_id_config.child_scopes.each do |klass|
            Slug.update_all "scope = '#{@new_friendly_id}'", ["sluggable_type = ? AND scope = ?", klass.to_s, slugs.second.to_friendly_id]
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