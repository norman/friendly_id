module FriendlyId
  module ActiveRecordAdapter
    module SluggedModel

      def self.included(base)
        base.class_eval do
          has_one :slug, :order => 'id DESC', :as => :sluggable, :dependent => :nullify
          has_many :slugs, :order => 'id DESC', :as => :sluggable, :dependent => :destroy
          before_save :build_a_slug
          after_save :set_slug_cache
          after_update :update_scope
          after_update :update_dependent_scopes
          protect_friendly_id_attributes

          def slug_with_rails_3_2_patch
            slug_without_rails_3_2_patch || slugs.first
          end

          alias_method_chain :slug, :rails_3_2_patch
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
        self.slug = slugs.build :name => slug_text.to_s, :scope => friendly_id_config.scope_for(self),
          :sluggable => self
        @new_friendly_id = self.slug.to_friendly_id
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
        return unless friendly_id_config.class.scopes_used?
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
      if !::ActiveRecord::Base.private_method_defined? :update_without_callbacks
        def update_without_callbacks
          attributes_with_values = arel_attributes_values(false, false, attribute_names)
          return false if attributes_with_values.empty?
          self.class.unscoped.where(self.class.arel_table[self.class.primary_key].eq(id)).arel.update(attributes_with_values)
        end
      end
    end
  end
end
