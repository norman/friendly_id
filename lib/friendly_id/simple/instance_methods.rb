module FriendlyId
  module Simple
    module InstanceMethods

      def self.included(base)
        base.validate :validate_friendly_id
      end

      attr :found_using_friendly_id

      # Was the record found using one of its friendly ids?
      def found_using_friendly_id?
        @found_using_friendly_id
      end

      # Was the record found using its numeric id?
      def found_using_numeric_id?
        !@found_using_friendly_id
      end
      alias has_better_id? found_using_numeric_id?

      # Returns the friendly_id.
      def friendly_id
        send friendly_id_config.method
      end
      alias best_id friendly_id

      # Returns the friendly id, or if none is available, the numeric id.
      def to_param
        (friendly_id || id).to_s
      end

      private

      def validate_friendly_id
        if self.class.friendly_id_config.reserved_words.include? friendly_id
          self.errors.add(self.class.friendly_id_config.method,
            self.class.friendly_id_config.reserved_message % friendly_id)
          return false
        end
      end

      def found_using_friendly_id=(value) #:nodoc#
        @found_using_friendly_id = value
      end

    end
  end
end
