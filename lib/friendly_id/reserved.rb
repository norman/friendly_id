module FriendlyId

=begin
This module adds the ability to exlude a list of words from use as
FriendlyId slugs.

By default, FriendlyId reserves the words "new" and "edit" when this module
is included. You can configure this globally by using {FriendlyId.defaults FriendlyId.defaults}:

  FriendlyId.defaults do |config|
    config.use :reserved
    # Reserve words for English and Spanish URLs
    config.reserved_words = %w(new edit nueva nuevo editar)
  end
=end
  module Reserved

    # When included, this module adds configuration options to the model class's
    # friendly_id_config.
    def self.included(model_class)
      model_class.class_eval do
        friendly_id_config.class.send :include, Reserved::Configuration
        friendly_id_config.defaults[:reserved_words] ||= ["new", "edit"]
      end
    end

    # This module adds the +:reserved_words+ configuration option to
    # {FriendlyId::Configuration FriendlyId::Configuration}.
    module Configuration
      attr_writer :reserved_words

      # Overrides {FriendlyId::Configuration#base} to add a validation to the
      # model class.
      def base=(base)
        super
        reserved_words = model_class.friendly_id_config.reserved_words
        model_class.validates_exclusion_of :friendly_id, :in => reserved_words
      end

      # An array of words forbidden as slugs.
      def reserved_words
        @reserved_words ||= @defaults[:reserved_words]
      end
    end
  end
end
