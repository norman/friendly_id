module FriendlyId
  module ActiveRecord2

    module DeprecatedSlugMethods
      # @deprecated Please use String#parse_friendly_id
      def parse(string)
        warn("Slug#parse is deprecated and will be removed in FriendlyId 3.0. Please use String#parse_friendly_id.")
        string.to_s.parse_friendly_id
      end

      # @deprecated Please use SlugString#normalize.
      def normalize(slug_text)
        warn("Slug#normalize is deprecated and will be removed in FriendlyId 3.0. Please use SlugString#normalize.")
        raise SlugGenerationError if slug_text.blank?
        SlugString.new(slug_text.to_s).normalize.to_s
      end

      # @deprecated Please use SlugString#approximate_ascii."
      def strip_diacritics(string)
        warn("Slug#strip_diacritics is deprecated and will be removed in FriendlyId 3.0. Please use SlugString#approximate_ascii.")
        raise SlugGenerationError if string.blank?
        SlugString.new(string).approximate_ascii
      end

      # @deprecated Please use SlugString#to_ascii.
      def strip_non_ascii(string)
        warn("Slug#strip_non_ascii is deprecated and will be removed in FriendlyId 3.0. Please use SlugString#to_ascii.")
        raise SlugGenerationError if string.blank?
        SlugString.new(string).to_ascii
      end

    end

    # A Slug is a unique, human-friendly identifier for an ActiveRecord.
    class Slug < ::ActiveRecord::Base

      extend DeprecatedSlugMethods

      table_name = "slugs"
      belongs_to :sluggable, :polymorphic => true
      before_save :enable_name_reversion, :set_sequence
      validate :validate_name
      named_scope :similar_to, lambda {|slug| {:conditions => {
            :name           => slug.name,
            :scope          => slug.scope,
            :sluggable_type => slug.sluggable_type
          },
          :order => "sequence ASC"
        }
      }

      # Whether this slug is the most recent of its owner's slugs.
      def current?
        sluggable.slug == self
      end

      # @deprecated Please used Slug#current?
      def is_most_recent?
        warn("Slug#is_most_recent? is deprecated and will be removed in FriendlyId 3.0. Please use Slug#current?")
        current?
      end

      def to_friendly_id
        sequence > 1 ? friendly_id_with_sequence : name
      end

      # Raise a FriendlyId::SlugGenerationError if the slug name is blank.
      def validate_name
        if name.blank?
          raise FriendlyId::SlugGenerationError.new("slug.name can not be blank.")
        end
      end

      private

      # If we're renaming back to a previously used friendly_id, delete the
      # slug so that we can recycle the name without having to use a sequence.
      def enable_name_reversion
        sluggable.slugs.find_all_by_name_and_scope(name, scope).each { |slug| slug.destroy }
      end

      def friendly_id_with_sequence
        "#{name}#{separator}#{sequence}"
      end

      def similar_to_other_slugs?
        !similar_slugs.empty?
      end

      def similar_slugs
        self.class.similar_to(self)
      end

      def separator
        sluggable.friendly_id_config.sequence_separator
      end

      def set_sequence
        return unless new_record?
        self.sequence = similar_slugs.last.sequence.succ if similar_to_other_slugs?
      end

    end
  end
end