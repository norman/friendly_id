module FriendlyId
  module Slugged

    class Status < FriendlyId::Status

      attr_accessor :sequence, :slug

      # Did the find operation use the best possible id? True if +id+ is
      # numeric, but the model has no slug, or +id+ is friendly and current
      def best?
        current? || (numeric? && !record.slug)
      end

      # Did the find operation use the current slug?
      def current?
        !! slug && slug.current?
      end

      # Did the find operation use a friendly id?
      def friendly?
        !! (name or slug)
      end

      def friendly_id=(friendly_id)
        @name, @sequence = friendly_id.parse_friendly_id(record.friendly_id_config.sequence_separator)
      end

      # Did the find operation use an outdated slug?
      def outdated?
        !current?
      end

      # The slug that was used to find the model.
      def slug
        @slug ||= record.find_slug(name, sequence)
      end

    end

    module Model
      attr_accessor :slug

      def find_slug
        raise NotImplementedError
      end

      def friendly_id_config
        self.class.friendly_id_config
      end

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

      # Does the instance have a slug?
      def slug?
        !! slug
      end

      private

      # Get the processed string used as the basis of the friendly id.
      def slug_text
        text = normalize_friendly_id(SlugString.new(send(friendly_id_config.method)))
        SlugString.new(text.to_s).validate_for!(friendly_id_config).to_s
      end

      # Has the slug text changed?
      def slug_text_changed?
        slug_text != slug.name
      end

      # Has the basis of our friendly id changed, requiring the generation of a
      # new slug?
      def new_slug_needed?
        !slug? || slug_text_changed?
      end

    end
  end
end
