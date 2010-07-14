module FriendlyId
  module ActiveRecordAdapter
    module SluggedModel

      module SluggedFinder
        # Whether :include => :slugs has been passed as an option.
        def slugs_included?
          [*(options[:include] or [])].to_a.flatten.include?(:slugs)
        end

        def handle_friendly_result
          raise ::ActiveRecord::RecordNotFound.new unless @result
          @result.friendly_id_status.friendly_id = id
        end

      end

      class MultipleFinder

        include FriendlyId::ActiveRecordAdapter::Finders::Multiple
        include SluggedFinder

        attr_reader :slugs

        def find
          @results = model_class.scoped(find_options).all(options).uniq
          raise ::ActiveRecord::RecordNotFound, error_message if @results.size != expected_size
          @results.each {|result| result.friendly_id_status.name = slug_for(result)}
        end

        private

        def find_conditions
          "%s IN (%s)" % [
            "#{quoted_table_name}.#{primary_key}",
            (unfriendly_ids + sluggable_ids).join(",")
          ]
        end

        def find_options
          {:select => "#{quoted_table_name}.*", :conditions => find_conditions,
            :joins => slugs_included? ? options[:joins] : :slugs}
        end

        def sluggable_ids
          @sluggable_ids ||= slugs.map(&:sluggable_id)
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
          end.compact
        end

        def slug_for(result)
          slugs.detect {|slug| result.id == slug.sluggable_id}
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
          @result = model_class.scoped(find_options).first(options)
          handle_friendly_result if @result or friendly_id_config.scope?
          @result
        rescue ::ActiveRecord::RecordNotFound => @error
          friendly_id_config.scope? ? raise_scoped_error : (raise @error)
        end

        private

        def find_options
          slug_table = Slug.table_name
          {
            :select => "#{model_class.quoted_table_name}.*",
            :joins => slugs_included? ? options[:joins] : :slugs,
            :conditions => {
              "#{slug_table}.name"     => name,
              "#{slug_table}.scope"    => scope,
              "#{slug_table}.sequence" => sequence
            }
          }
        end

        def raise_scoped_error
          scope_message = scope || "expected, but none given"
          message = "%s, scope: %s" % [@error.message, scope_message]
          raise ::ActiveRecord::RecordNotFound, message
        end

      end

      # Performs a find for multiple friendly_ids using the cached_slug column,
      # if available. This is significantly faster, and can be used in all
      # circumstances unless the +:scope+ argument is present.
      class CachedSingleFinder < SimpleModel::SingleFinder

        include SluggedFinder

        def find
          @result = model_class.scoped(find_options).first(options)
          if @result
            handle_friendly_result
            @result
          else
            uncached_find
          end
        rescue ActiveRecord::RecordNotFound
          uncached_find
        end

        def uncached_find
          SingleFinder.new(id, model_class, options).find
        end

        # The column used to store the cached slug.
        def column
          "#{table_name}.#{friendly_id_config.cache_column}"
        end

      end

      def self.included(base)
        base.class_eval do
          has_many :slugs, :order => 'id DESC', :as => :sluggable, :dependent => :destroy
          has_one :slug, :order => 'id DESC', :as => :sluggable, :dependent => :destroy
          before_save :build_a_slug
          after_save :set_slug_cache
          after_update :update_scope
          after_update :update_dependent_scopes
          protect_friendly_id_attributes
          extend FriendlyId::ActiveRecordAdapter::FinderMethods unless FriendlyId.on_ar3?
        end
      end

      include FriendlyId::Slugged::Model

      def find_slug(name, sequence)
        slugs.find_by_name_and_sequence(name, sequence)
      end

      # Returns the friendly id, or if none is available, the numeric id. Note that this
      # method will use the cached_slug value if present, unlike {#friendly_id}.
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
      def build_a_slug
        return unless new_slug_needed?
        @slug = slugs.build :name => slug_text.to_s, :scope => friendly_id_config.scope_for(self),
          :sluggable => self
        @new_friendly_id = @slug.to_friendly_id
      end

      # Reset the cached friendly_id?
      def new_cache_needed?
        uses_slug_cache? && slug? && send(friendly_id_config.cache_column) != slug.to_friendly_id
      end

      # Reset the cached friendly_id.
      def set_slug_cache
        if new_cache_needed?
          begin
            send "#{friendly_id_config.cache_column}=", slug.to_friendly_id
            update_without_callbacks
          rescue ActiveRecord::StaleObjectError
            reload
            retry
          end
        end
      end

      def update_scope
        return unless slug && scope_changed?
        self.class.transaction do
          slug.scope = send(friendly_id_config.scope).to_param
          similar = Slug.similar_to(slug)
          if !similar.empty?
            slug.sequence = similar.first.sequence.succ
          end
          slug.save!
        end
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

      # This method was removed in ActiveRecord 3.0.
      if !ActiveRecord::Base.private_method_defined? :update_without_callbacks
        def update_without_callbacks
          save :callbacks => false
        end
      end

    end
  end
end
