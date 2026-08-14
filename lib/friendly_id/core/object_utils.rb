module FriendlyId
  # Instances of these classes will never be considered a friendly id.
  # @see FriendlyId::ObjectUtils#friendly_id
  UNFRIENDLY_CLASSES = [
    Array,
    FalseClass,
    Hash,
    NilClass,
    Numeric,
    Symbol,
    TrueClass
  ]

  # Utility methods for determining whether any object is a friendly id.
  #
  # @deprecated Since 6.0, prefer {FriendlyId.friendly_id?} and
  #   {FriendlyId.unfriendly_id?}, which do the same job without patching
  #   `Object`. This module is still mixed into `Object` by the Active Record
  #   adapter for backwards compatibility, and will be removed in 7.0. Core
  #   defines it but installs nothing.
  module ObjectUtils
    # True if the id is definitely friendly, false if definitely unfriendly,
    # else nil.
    #
    # An object is considired "definitely unfriendly" if its class is or
    # inherits from ActiveRecord::Base, Array, Hash, NilClass, Numeric, or
    # Symbol.
    #
    # An object is considered "definitely friendly" if it responds to +to_i+,
    # and its value when cast to an integer and then back to a string is
    # different from its value when merely cast to a string:
    #
    #     123.friendly_id?                  #=> false
    #     :id.friendly_id?                  #=> false
    #     {:name => 'joe'}.friendly_id?     #=> false
    #     ['name = ?', 'joe'].friendly_id?  #=> false
    #     nil.friendly_id?                  #=> false
    #     "123".friendly_id?                #=> nil
    #     "abc123".friendly_id?             #=> true
    def friendly_id?
      true if respond_to?(:to_i) && to_i.to_s != to_s
    end

    # True if the id is definitely unfriendly, false if definitely friendly,
    # else nil.
    def unfriendly_id?
      val = friendly_id?
      !val unless val.nil?
    end
  end

  module UnfriendlyUtils
    def friendly_id?
      false
    end

    def unfriendly_id?
      true
    end
  end

  def self.mark_as_unfriendly(klass)
    klass.send(:include, FriendlyId::UnfriendlyUtils)
  end

  # The supported way to ask whether a value looks like a friendly id.
  #
  # Note that this deliberately does not depend on {mark_as_unfriendly} having
  # been called on the core classes: it consults {UNFRIENDLY_CLASSES} directly,
  # so it gives the same answers whether or not an adapter has installed the
  # deprecated `Object#friendly_id?` patch.
  #
  # @return true if definitely friendly, false if definitely unfriendly, else nil
  def self.friendly_id?(value)
    return false if value.is_a?(FriendlyId::UnfriendlyUtils)
    return false if UNFRIENDLY_CLASSES.any? { |klass| value.is_a?(klass) }

    true if value.respond_to?(:to_i) && value.to_i.to_s != value.to_s
  end

  def self.unfriendly_id?(value)
    friendly = friendly_id?(value)
    !friendly unless friendly.nil?
  end
end

# Core installs no patches. The Active Record adapter mixes {ObjectUtils} into
# `Object` and marks {UNFRIENDLY_CLASSES} for backwards compatibility, and marks
# `ActiveRecord::Base` unfriendly so that model instances are never mistaken for
# ids. See `friendly_id/active_record`.
