module FriendlyId

=begin

## Reserved Words

The {FriendlyId::Reserved Reserved} module adds the ability to exlude a list of
words from use as FriendlyId slugs.

With Ruby on Rails, FriendlyId's generator generates an initializer that
reserves the words "new" and "edit" using {FriendlyId.defaults
FriendlyId.defaults}.

Note that the error messages for fields will appear on the field
`:friendly_id`. If you are using Rails's scaffolded form errors display, then
it will have no field to highlight. If you'd like to change this so that
scaffolding works as expected, one way to accomplish this is to move the error
message to a different field. For example:

  class Person < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, use: :slugged

    after_validation :move_friendly_id_error_to_name

    def move_friendly_id_error_to_name
      errors.add :name, *errors.delete(:friendly_id) if errors[:friendly_id].present?
    end
  end

=end
  module Reserved

    # When included, this module adds configuration options to the model class's
    # friendly_id_config.
    def self.included(model_class)
      model_class.class_eval do
        friendly_id_config.class.send :include, Reserved::Configuration
        friendly_id_config.defaults[:reserved_words] ||= []
      end
    end

    # This module adds the `:reserved_words` configuration option to
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
