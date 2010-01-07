module FriendlyId
  module Slugged

    # FriendlyId::Finder presents information about the status of the
    # id that was used to find the model: whether it was found using a
    # numeric id or friendly id, whether the friendly id used to find the
    # model is the most current one.
    class Finder

      attr_accessor :name
      attr_accessor :slug
      attr_accessor :model

      def initialize(options={})
        options.each {|key, value| self.send("#{key}=".to_sym, value)}
      end

      # The slug that was used to find the model.
      def slug
        @slug ||= model.slugs.find_by_name_and_sequence(*FriendlyId.parse_friendly_id(name))
      end

      # Did the find operation use a friendly id?
      def friendly?
        !! (name or slug)
      end

      # Did the find operation use a numeric id?
      def numeric?
        !friendly?
      end

      # Did the find operation use the current slug?
      def current?
        slug.is_most_recent?
      end

      # Did the find operation use an outdated slug?
      def outdated?
        current?
      end

      # Did the find operation use the best possible id? True if there is
      # a slug, and the most recent one was used.
      def best?
        friendly? and current?
      end

    end

  end
end
