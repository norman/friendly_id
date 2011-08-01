module FriendlyId

  # This module adds the ability to exlude a list of words from use as
  # FriendlyId slugs.
  module Reserved
    def self.included(model_class)
      model_class.class_eval do
        friendly_id_config.class.send :include, Reserved::Configuration
        friendly_id_config.defaults[:reserved_words] ||= ["new", "edit"]
      end
    end

    module Configuration
      attr_writer :reserved_words

      def base=(base)
        super
        reserved_words = model_class.friendly_id_config.reserved_words
        model_class.validates_exclusion_of base, :in => reserved_words
      end

      def reserved_words
        @reserved_words ||= @defaults[:reserved_words]
      end
    end
  end
end