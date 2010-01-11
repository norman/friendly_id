# A Slug is a unique, human-friendly identifier for an ActiveRecord.
module FriendlyId
  module Adapters
    module ActiveRecord

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

      class Slug < ::ActiveRecord::Base

        extend DeprecatedSlugMethods

        belongs_to :sluggable, :polymorphic => true
        before_save :set_sequence
        table_name = "slugs"

        # Whether this slug is the most recent of its owner's slugs.
        def is_most_recent?
          sluggable.slug == self
        end

        def to_friendly_id
          sequence > 1 ? friendly_id_with_sequence : name
        end

        # Raise a FriendlyId::SlugGenerationError if the slug name is blank.
        def validate #:nodoc:#
          if name.blank?
            raise FriendlyId::SlugGenerationError.new("slug.name can not be blank.")
          end
        end

        private

        def friendly_id_with_sequence
          "#{name}#{separator}#{sequence}"
        end

        def separator
          sluggable.friendly_id_config.sequence_separator
        end

        def set_sequence
          return unless new_record?
          last = Slug.find(:first, :conditions => { :name => name, :scope => scope,
            :sluggable_type => sluggable_type}, :order => "sequence DESC",
            :select => 'sequence')
          self.sequence = last.sequence + 1 if last
        end

      end
    end
  end
end